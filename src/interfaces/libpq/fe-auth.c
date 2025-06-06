/*-------------------------------------------------------------------------
 *
 * fe-auth.c
 *	   The front-end (client) authorization routines
 *
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/interfaces/libpq/fe-auth.c
 *
 *-------------------------------------------------------------------------
 */

/*
 * INTERFACE ROUTINES
 *	   frontend (client) routines:
 *		pg_fe_sendauth			send authentication information
 *		pg_fe_getauthname		get user's name according to the client side
 *								of the authentication system
 */

/*
 * This file is compiled with both frontend and backend codes, symlinked by
 * src/backend/Makefile, and use macro FRONTEND to switch.
 *
 * Include "c.h" to adopt Greengage C types. Don't include "postgres_fe.h",
 * which only defines FRONTEND besides including "c.h"
 */
#include "c.h"

#ifdef WIN32
#include "win32.h"
#else
#include <unistd.h>
#include <fcntl.h>
#include <sys/param.h>			/* for MAXHOSTNAMELEN on most */
#include <sys/socket.h>
#ifdef HAVE_SYS_UCRED_H
#include <sys/ucred.h>
#endif
#ifndef  MAXHOSTNAMELEN
#include <netdb.h>				/* for MAXHOSTNAMELEN on some */
#endif
#include <pwd.h>
#endif


#include "common/scram-common.h"
#include "libpq-fe.h"
#include "fe-auth.h"
#include "libpq/md5.h"
#include "libpq/pg_sha2.h"

#if HAVE_GSSAPI_PROXY
#include <gssapi/gssapi_ext.h>
#include <gssapi/gssapi_krb5.h>
#endif

#ifdef ENABLE_GSS
/*
 * GSSAPI authentication system.
 */

#if defined(WIN32) && !defined(WIN32_ONLY_COMPILER)
/*
 * MIT Kerberos GSSAPI DLL doesn't properly export the symbols for MingW
 * that contain the OIDs required. Redefine here, values copied
 * from src/athena/auth/krb5/src/lib/gssapi/generic/gssapi_generic.c
 */
const gss_OID_desc GSS_C_NT_HOSTBASED_SERVICE_desc =
{10, (void *) "\x2a\x86\x48\x86\xf7\x12\x01\x02\x01\x04"};
GSS_DLLIMP gss_OID GSS_C_NT_HOSTBASED_SERVICE = &GSS_C_NT_HOSTBASED_SERVICE_desc;
#endif

/*
 * Fetch all errors of a specific type and append to "str".
 */
static void
pg_GSS_error_int(PQExpBuffer str, const char *mprefix,
				 OM_uint32 stat, int type)
{
	OM_uint32	lmin_s;
	gss_buffer_desc lmsg;
	OM_uint32	msg_ctx = 0;

	do
	{
		gss_display_status(&lmin_s, stat, type,
						   GSS_C_NO_OID, &msg_ctx, &lmsg);
		appendPQExpBuffer(str, "%s: %s\n", mprefix, (char *) lmsg.value);
		gss_release_buffer(&lmin_s, &lmsg);
	} while (msg_ctx);
}

/*
 * GSSAPI errors contain two parts; put both into conn->errorMessage.
 */
static void
pg_GSS_error(const char *mprefix, PGconn *conn,
			 OM_uint32 maj_stat, OM_uint32 min_stat)
{
	resetPQExpBuffer(&conn->errorMessage);

	/* Fetch major error codes */
	pg_GSS_error_int(&conn->errorMessage, mprefix, maj_stat, GSS_C_GSS_CODE);

	/* Add the minor codes as well */
	pg_GSS_error_int(&conn->errorMessage, mprefix, min_stat, GSS_C_MECH_CODE);
}

/*
 * Check if we can acquire credentials at all (and yield them if so).
 */
static bool
pg_GSS_have_ccache(gss_cred_id_t *cred_out)
{
#if HAVE_GSSAPI_PROXY
	OM_uint32	major, minor;
	gss_cred_id_t cred = GSS_C_NO_CREDENTIAL;
	gss_key_value_element_desc cc;
	gss_key_value_set_desc ccset;
	const char *ccache_name = "MEMORY:proxy";

	cc.key = "ccache";
	cc.value = ccache_name;
	ccset.count = 1;
	ccset.elements = &cc;

	major = gss_acquire_cred_from(&minor, GSS_C_NO_NAME, GSS_C_INDEFINITE, GSS_C_NO_OID_SET,
							 GSS_C_INITIATE, &ccset, &cred, NULL, NULL);
	if (major != GSS_S_COMPLETE)
	{
		*cred_out = NULL;
		return false;
	}
	*cred_out = cred;
	return true;
#else
	return false;
#endif
}

/*
 * Continue GSS authentication with next token as needed.
 */
static int
pg_GSS_continue(PGconn *conn)
{
	OM_uint32	maj_stat,
				min_stat,
				lmin_s;
	gss_cred_id_t proxy;

	/* Check if we can aquire a proxy credential. */
	if (!pg_GSS_have_ccache(&proxy))
	{
		proxy = GSS_C_NO_CREDENTIAL;
	}
	maj_stat = gss_init_sec_context(&min_stat,
									proxy,
									&conn->gctx,
									conn->gtarg_nam,
									GSS_C_NO_OID,
									GSS_C_MUTUAL_FLAG | GSS_C_DELEG_FLAG,
									0,
									GSS_C_NO_CHANNEL_BINDINGS,
				(conn->gctx == GSS_C_NO_CONTEXT) ? GSS_C_NO_BUFFER : &conn->ginbuf,
									NULL,
									&conn->goutbuf,
									NULL,
									NULL);

	if (conn->gctx != GSS_C_NO_CONTEXT)
	{
		free(conn->ginbuf.value);
		conn->ginbuf.value = NULL;
		conn->ginbuf.length = 0;
	}

	if (conn->goutbuf.length != 0)
	{
		/*
		 * GSS generated data to send to the server. We don't care if it's the
		 * first or subsequent packet, just send the same kind of password
		 * packet.
		 */
		if (pqPacketSend(conn, 'p',
						 conn->goutbuf.value, conn->goutbuf.length)
			!= STATUS_OK)
		{
			gss_release_buffer(&lmin_s, &conn->goutbuf);
			return STATUS_ERROR;
		}
	}
	gss_release_buffer(&lmin_s, &conn->goutbuf);

	if (maj_stat != GSS_S_COMPLETE && maj_stat != GSS_S_CONTINUE_NEEDED)
	{
		pg_GSS_error(libpq_gettext("GSSAPI continuation error"),
					 conn,
					 maj_stat, min_stat);
		gss_release_name(&lmin_s, &conn->gtarg_nam);
		if (conn->gctx)
			gss_delete_sec_context(&lmin_s, &conn->gctx, GSS_C_NO_BUFFER);
		return STATUS_ERROR;
	}

	if (maj_stat == GSS_S_COMPLETE)
		gss_release_name(&lmin_s, &conn->gtarg_nam);

	return STATUS_OK;
}

/*
 * Send initial GSS authentication token
 */
static int
pg_GSS_startup(PGconn *conn)
{
	OM_uint32	maj_stat,
				min_stat;
	int			maxlen;
	gss_buffer_desc temp_gbuf;

	if (!(conn->pghost && conn->pghost[0] != '\0'))
	{
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("host name must be specified\n"));
		return STATUS_ERROR;
	}

	if (conn->gctx)
	{
		printfPQExpBuffer(&conn->errorMessage,
					libpq_gettext("duplicate GSS authentication request\n"));
		return STATUS_ERROR;
	}

	/*
	 * Import service principal name so the proper ticket can be acquired by
	 * the GSSAPI system.
	 */
	maxlen = NI_MAXHOST + strlen(conn->krbsrvname) + 2;
	temp_gbuf.value = (char *) malloc(maxlen);
	if (!temp_gbuf.value)
	{
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("out of memory\n"));
		return STATUS_ERROR;
	}
	snprintf(temp_gbuf.value, maxlen, "%s@%s",
			 conn->krbsrvname, conn->pghost);
	temp_gbuf.length = strlen(temp_gbuf.value);

	maj_stat = gss_import_name(&min_stat, &temp_gbuf,
							   GSS_C_NT_HOSTBASED_SERVICE, &conn->gtarg_nam);
	free(temp_gbuf.value);

	if (maj_stat != GSS_S_COMPLETE)
	{
		pg_GSS_error(libpq_gettext("GSSAPI name import error"),
					 conn,
					 maj_stat, min_stat);
		return STATUS_ERROR;
	}

	/*
	 * Initial packet is the same as a continuation packet with no initial
	 * context.
	 */
	conn->gctx = GSS_C_NO_CONTEXT;

	return pg_GSS_continue(conn);
}
#endif   /* ENABLE_GSS */


#ifdef ENABLE_SSPI
/*
 * SSPI authentication system (Windows only)
 */

static void
pg_SSPI_error(PGconn *conn, const char *mprefix, SECURITY_STATUS r)
{
	char		sysmsg[256];

	if (FormatMessage(FORMAT_MESSAGE_IGNORE_INSERTS |
					  FORMAT_MESSAGE_FROM_SYSTEM,
					  NULL, r, 0,
					  sysmsg, sizeof(sysmsg), NULL) == 0)
		printfPQExpBuffer(&conn->errorMessage, "%s: SSPI error %x",
						  mprefix, (unsigned int) r);
	else
		printfPQExpBuffer(&conn->errorMessage, "%s: %s (%x)",
						  mprefix, sysmsg, (unsigned int) r);
}

/*
 * Continue SSPI authentication with next token as needed.
 */
static int
pg_SSPI_continue(PGconn *conn)
{
	SECURITY_STATUS r;
	CtxtHandle	newContext;
	ULONG		contextAttr;
	SecBufferDesc inbuf;
	SecBufferDesc outbuf;
	SecBuffer	OutBuffers[1];
	SecBuffer	InBuffers[1];

	if (conn->sspictx != NULL)
	{
		/*
		 * On runs other than the first we have some data to send. Put this
		 * data in a SecBuffer type structure.
		 */


		inbuf.ulVersion = SECBUFFER_VERSION;
		inbuf.cBuffers = 1;
		inbuf.pBuffers = InBuffers;
		InBuffers[0].pvBuffer = conn->ginbuf.value;
		InBuffers[0].cbBuffer = conn->ginbuf.length;
		InBuffers[0].BufferType = SECBUFFER_TOKEN;
	}

	OutBuffers[0].pvBuffer = NULL;
	OutBuffers[0].BufferType = SECBUFFER_TOKEN;
	OutBuffers[0].cbBuffer = 0;
	outbuf.cBuffers = 1;
	outbuf.pBuffers = OutBuffers;
	outbuf.ulVersion = SECBUFFER_VERSION;

	r = InitializeSecurityContext(conn->sspicred,
								  conn->sspictx,
								  conn->sspitarget,
								  ISC_REQ_ALLOCATE_MEMORY,
								  0,
								  SECURITY_NETWORK_DREP,
								  (conn->sspictx == NULL) ? NULL : &inbuf,
								  0,
								  &newContext,
								  &outbuf,
								  &contextAttr,
								  NULL);

	if (r != SEC_E_OK && r != SEC_I_CONTINUE_NEEDED)
	{
		pg_SSPI_error(conn, libpq_gettext("SSPI continuation error"), r);

		return STATUS_ERROR;
	}

	if (conn->sspictx == NULL)
	{
		/* On first run, transfer retrieved context handle */
		conn->sspictx = malloc(sizeof(CtxtHandle));
		if (conn->sspictx == NULL)
		{
			printfPQExpBuffer(&conn->errorMessage, libpq_gettext("out of memory\n"));
			return STATUS_ERROR;
		}
		memcpy(conn->sspictx, &newContext, sizeof(CtxtHandle));
	}
	else
	{
		/*
		 * On subsequent runs when we had data to send, free buffers that
		 * contained this data.
		 */
		free(conn->ginbuf.value);
		conn->ginbuf.value = NULL;
		conn->ginbuf.length = 0;
	}

	/*
	 * If SSPI returned any data to be sent to the server (as it normally
	 * would), send this data as a password packet.
	 */
	if (outbuf.cBuffers > 0)
	{
		if (outbuf.cBuffers != 1)
		{
			/*
			 * This should never happen, at least not for Kerberos
			 * authentication. Keep check in case it shows up with other
			 * authentication methods later.
			 */
			printfPQExpBuffer(&conn->errorMessage, "SSPI returned invalid number of output buffers\n");
			return STATUS_ERROR;
		}

		/*
		 * If the negotiation is complete, there may be zero bytes to send.
		 * The server is at this point not expecting any more data, so don't
		 * send it.
		 */
		if (outbuf.pBuffers[0].cbBuffer > 0)
		{
			if (pqPacketSend(conn, 'p',
				   outbuf.pBuffers[0].pvBuffer, outbuf.pBuffers[0].cbBuffer))
			{
				FreeContextBuffer(outbuf.pBuffers[0].pvBuffer);
				return STATUS_ERROR;
			}
		}
		FreeContextBuffer(outbuf.pBuffers[0].pvBuffer);
	}

	/* Cleanup is handled by the code in freePGconn() */
	return STATUS_OK;
}

/*
 * Send initial SSPI authentication token.
 * If use_negotiate is 0, use kerberos authentication package which is
 * compatible with Unix. If use_negotiate is 1, use the negotiate package
 * which supports both kerberos and NTLM, but is not compatible with Unix.
 */
static int
pg_SSPI_startup(PGconn *conn, int use_negotiate)
{
	SECURITY_STATUS r;
	TimeStamp	expire;

	if (conn->sspictx)
	{
		printfPQExpBuffer(&conn->errorMessage,
					libpq_gettext("duplicate SSPI authentication request\n"));
		return STATUS_ERROR;
	}

	/*
	 * Retreive credentials handle
	 */
	conn->sspicred = malloc(sizeof(CredHandle));
	if (conn->sspicred == NULL)
	{
		printfPQExpBuffer(&conn->errorMessage, libpq_gettext("out of memory\n"));
		return STATUS_ERROR;
	}

	r = AcquireCredentialsHandle(NULL,
								 use_negotiate ? "negotiate" : "kerberos",
								 SECPKG_CRED_OUTBOUND,
								 NULL,
								 NULL,
								 NULL,
								 NULL,
								 conn->sspicred,
								 &expire);
	if (r != SEC_E_OK)
	{
		pg_SSPI_error(conn, libpq_gettext("could not acquire SSPI credentials"), r);
		free(conn->sspicred);
		conn->sspicred = NULL;
		return STATUS_ERROR;
	}

	/*
	 * Compute target principal name. SSPI has a different format from GSSAPI,
	 * but not more complex. We can skip the @REALM part, because Windows will
	 * fill that in for us automatically.
	 */
	if (!(conn->pghost && conn->pghost[0] != '\0'))
	{
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("host name must be specified\n"));
		return STATUS_ERROR;
	}
	conn->sspitarget = malloc(strlen(conn->krbsrvname) + strlen(conn->pghost) + 2);
	if (!conn->sspitarget)
	{
		printfPQExpBuffer(&conn->errorMessage, libpq_gettext("out of memory\n"));
		return STATUS_ERROR;
	}
	sprintf(conn->sspitarget, "%s/%s", conn->krbsrvname, conn->pghost);

	/*
	 * Indicate that we're in SSPI authentication mode to make sure that
	 * pg_SSPI_continue is called next time in the negotiation.
	 */
	conn->usesspi = 1;

	return pg_SSPI_continue(conn);
}
#endif   /* ENABLE_SSPI */

/*
 * Initialize SASL authentication exchange.
 */
static int
pg_SASL_init(PGconn *conn, int payloadlen)
{
	char	   *initialresponse = NULL;
	int			initialresponselen;
	bool		done;
	bool		success;
	const char *selected_mechanism;
	PQExpBufferData mechanism_buf;
	char	   *password;

	initPQExpBuffer(&mechanism_buf);

	if (conn->sasl_state)
	{
		printfPQExpBuffer(&conn->errorMessage,
				   libpq_gettext("duplicate SASL authentication request\n"));
		goto error;
	}

	/*
	 * Parse the list of SASL authentication mechanisms in the
	 * AuthenticationSASL message, and select the best mechanism that we
	 * support.  SCRAM-SHA-256-PLUS and SCRAM-SHA-256 are the only ones
	 * supported at the moment, listed by order of decreasing importance.
	 */
	selected_mechanism = NULL;
	for (;;)
	{
		if (pqGets(&mechanism_buf, conn))
		{
			printfPQExpBuffer(&conn->errorMessage,
							  "fe_sendauth: invalid authentication request from server: invalid list of authentication mechanisms\n");
			goto error;
		}
		if (PQExpBufferDataBroken(mechanism_buf))
			goto oom_error;

		/* An empty string indicates end of list */
		if (mechanism_buf.data[0] == '\0')
			break;

		/*
		 * Select the mechanism to use.  Pick SCRAM-SHA-256-PLUS over anything
		 * else if a channel binding type is set and if the client supports
		 * it. Pick SCRAM-SHA-256 if nothing else has already been picked.  If
		 * we add more mechanisms, a more refined priority mechanism might
		 * become necessary.
		 */
		if (strcmp(mechanism_buf.data, SCRAM_SHA_256_PLUS_NAME) == 0)
		{
#ifdef HAVE_PGTLS_GET_PEER_CERTIFICATE_HASH
			if (conn->ssl != NULL)
			{
				/*
				 * The server has offered SCRAM-SHA-256-PLUS, which is only
				 * supported by the client if a hash of the peer certificate
				 * can be created.
				 */

				selected_mechanism = SCRAM_SHA_256_PLUS_NAME;
			}
			else
#endif
			{
				/*
				 * The server offered SCRAM-SHA-256-PLUS, but the connection
				 * is not SSL-encrypted. That's not sane. Perhaps SSL was
				 * stripped by a proxy? There's no point in continuing,
				 * because the server will reject the connection anyway if we
				 * try authenticate without channel binding even though both
				 * the client and server supported it. The SCRAM exchange
				 * checks for that, to prevent downgrade attacks.
				 */
				printfPQExpBuffer(&conn->errorMessage,
								  libpq_gettext("server offered SCRAM-SHA-256-PLUS authentication over a non-SSL connection\n"));
				goto error;
			}
		}
		else if (strcmp(mechanism_buf.data, SCRAM_SHA_256_NAME) == 0 &&
				 !selected_mechanism)
			selected_mechanism = SCRAM_SHA_256_NAME;
	}

	if (!selected_mechanism)
	{
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("none of the server's SASL authentication mechanisms are supported\n"));
		goto error;
	}

	/*
	 * Now that the SASL mechanism has been chosen for the exchange,
	 * initialize its state information.
	 */

	/*
	 * First, select the password to use for the exchange, complaining if
	 * there isn't one.  Currently, all supported SASL mechanisms require a
	 * password, so we can just go ahead here without further distinction.
	 */
	conn->password_needed = true;
	password = conn->pgpass;
	if (password == NULL || password[0] == '\0')
	{
		printfPQExpBuffer(&conn->errorMessage,
						  PQnoPasswordSupplied);
		goto error;
	}

	/*
	 * Initialize the SASL state information with all the information
	 * gathered during the initial exchange.
	 *
	 * Note: Only tls-unique is supported for the moment.
	 */
	conn->sasl_state = pg_fe_scram_init(conn,
										password,
										selected_mechanism);
	if (!conn->sasl_state)
		goto oom_error;

	/* Get the mechanism-specific Initial Client Response, if any */
	pg_fe_scram_exchange(conn->sasl_state,
						 NULL, -1,
						 &initialresponse, &initialresponselen,
						 &done, &success);

	if (done && !success)
		goto error;

	/*
	 * Build a SASLInitialResponse message, and send it.
	 */
	if (pqPutMsgStart('p', true, conn))
		goto error;
	if (pqPuts(selected_mechanism, conn))
		goto error;
	if (initialresponse)
	{
		if (pqPutInt(initialresponselen, 4, conn))
			goto error;
		if (pqPutnchar(initialresponse, initialresponselen, conn))
			goto error;
	}
	if (pqPutMsgEnd(conn))
		goto error;
	if (pqFlush(conn))
		goto error;

	termPQExpBuffer(&mechanism_buf);
	if (initialresponse)
		free(initialresponse);

	return STATUS_OK;

error:
	termPQExpBuffer(&mechanism_buf);
	if (initialresponse)
		free(initialresponse);
	return STATUS_ERROR;

oom_error:
	termPQExpBuffer(&mechanism_buf);
	if (initialresponse)
		free(initialresponse);
	printfPQExpBuffer(&conn->errorMessage,
					  libpq_gettext("out of memory\n"));
	return STATUS_ERROR;
}

/*
 * Exchange a message for SASL communication protocol with the backend.
 * This should be used after calling pg_SASL_init to set up the status of
 * the protocol.
 */
static int
pg_SASL_continue(PGconn *conn, int payloadlen, bool final)
{
	char	   *output;
	int			outputlen;
	bool		done;
	bool		success;
	int			res;
	char	   *challenge;

	/* Read the SASL challenge from the AuthenticationSASLContinue message. */
	challenge = malloc(payloadlen + 1);
	if (!challenge)
	{
		printfPQExpBuffer(&conn->errorMessage,
				libpq_gettext("out of memory allocating SASL buffer (%d)\n"),
						  payloadlen);
		return STATUS_ERROR;
	}

	if (pqGetnchar(challenge, payloadlen, conn))
	{
		free(challenge);
		return STATUS_ERROR;
	}
	/* For safety and convenience, ensure the buffer is NULL-terminated. */
	challenge[payloadlen] = '\0';

	pg_fe_scram_exchange(conn->sasl_state,
						 challenge, payloadlen,
						 &output, &outputlen,
						 &done, &success);
	free(challenge);			/* don't need the input anymore */

	if (final && !done)
	{
		if (outputlen != 0)
			free(output);

		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("AuthenticationSASLFinal received from server, but SASL authentication was not completed\n"));
		return STATUS_ERROR;
	}
	if (outputlen != 0)
	{
		/*
		 * Send the SASL response to the server.
		 */
		res = pqPacketSend(conn, 'p', output, outputlen);
		free(output);

		if (res != STATUS_OK)
			return STATUS_ERROR;
	}

	if (done && !success)
		return STATUS_ERROR;

	return STATUS_OK;
}

/*
 * Respond to AUTH_REQ_SCM_CREDS challenge.
 *
 * Note: this is dead code as of Postgres 9.1, because current backends will
 * never send this challenge.  But we must keep it as long as libpq needs to
 * interoperate with pre-9.1 servers.  It is believed to be needed only on
 * Debian/kFreeBSD (ie, FreeBSD kernel with Linux userland, so that the
 * getpeereid() function isn't provided by libc).
 */
static int
pg_local_sendauth(PGconn *conn)
{
#ifdef HAVE_STRUCT_CMSGCRED
	char		buf;
	struct iovec iov;
	struct msghdr msg;
	struct cmsghdr *cmsg;
	union
	{
		struct cmsghdr hdr;
		unsigned char buf[CMSG_SPACE(sizeof(struct cmsgcred))];
	}			cmsgbuf;

	/*
	 * The backend doesn't care what we send here, but it wants exactly one
	 * character to force recvmsg() to block and wait for us.
	 */
	buf = '\0';
	iov.iov_base = &buf;
	iov.iov_len = 1;

	memset(&msg, 0, sizeof(msg));
	msg.msg_iov = &iov;
	msg.msg_iovlen = 1;

	/* We must set up a message that will be filled in by kernel */
	memset(&cmsgbuf, 0, sizeof(cmsgbuf));
	msg.msg_control = &cmsgbuf.buf;
	msg.msg_controllen = sizeof(cmsgbuf.buf);
	cmsg = CMSG_FIRSTHDR(&msg);
	cmsg->cmsg_len = CMSG_LEN(sizeof(struct cmsgcred));
	cmsg->cmsg_level = SOL_SOCKET;
	cmsg->cmsg_type = SCM_CREDS;

	if (sendmsg(conn->sock, &msg, 0) == -1)
	{
		char		sebuf[256];

		printfPQExpBuffer(&conn->errorMessage,
						  "pg_local_sendauth: sendmsg: %s\n",
						  pqStrerror(errno, sebuf, sizeof(sebuf)));
		return STATUS_ERROR;
	}
	return STATUS_OK;
#else
	printfPQExpBuffer(&conn->errorMessage,
			libpq_gettext("SCM_CRED authentication method not supported\n"));
	return STATUS_ERROR;
#endif
}

static int
pg_password_sendauth(PGconn *conn, const char *password, AuthRequest areq)
{
	int			ret;
	char	   *crypt_pwd = NULL;
	const char *pwd_to_send;
	char		md5Salt[4];

	/* Read the salt from the AuthenticationMD5 message. */
	if (areq == AUTH_REQ_MD5)
	{
		if (pqGetnchar(md5Salt, 4, conn))
			return STATUS_ERROR;	/* shouldn't happen */
	}

	/* Encrypt the password if needed. */

	switch (areq)
	{
		case AUTH_REQ_MD5:
			{
				char	   *crypt_pwd2;

				/* Allocate enough space for two MD5 hashes */
				crypt_pwd = malloc(2 * (MD5_PASSWD_LEN + 1));
				if (!crypt_pwd)
				{
					printfPQExpBuffer(&conn->errorMessage,
									  libpq_gettext("out of memory\n"));
					return STATUS_ERROR;
				}

				crypt_pwd2 = crypt_pwd + MD5_PASSWD_LEN + 1;
				if (!pg_md5_encrypt(password, conn->pguser,
									strlen(conn->pguser), crypt_pwd2))
				{
					free(crypt_pwd);
					return STATUS_ERROR;
				}
				if (!pg_md5_encrypt(crypt_pwd2 + strlen("md5"), md5Salt,
									4, crypt_pwd))
				{
					free(crypt_pwd);
					return STATUS_ERROR;
				}

				pwd_to_send = crypt_pwd;
				break;
			}
		case AUTH_REQ_PASSWORD:
			pwd_to_send = password;
			break;
		default:
			return STATUS_ERROR;
	}
	/* Packet has a message type as of protocol 3.0 */
	if (PG_PROTOCOL_MAJOR(conn->pversion) >= 3)
		ret = pqPacketSend(conn, 'p', pwd_to_send, strlen(pwd_to_send) + 1);
	else
		ret = pqPacketSend(conn, 0, pwd_to_send, strlen(pwd_to_send) + 1);
	if (crypt_pwd)
		free(crypt_pwd);
	return ret;
}

/*
 * pg_fe_sendauth
 *		client demux routine for processing an authentication request
 *
 * The server has sent us an authentication challenge (or OK). Send an
 * appropriate response. The caller has ensured that the whole message is
 * now in the input buffer, and has already read the type and length of
 * it. We are responsible for reading any remaining extra data, specific
 * to the authentication method. 'payloadlen' is the remaining length in
 * the message.
 */
int
pg_fe_sendauth(AuthRequest areq, int payloadlen, PGconn *conn)
{
	switch (areq)
	{
		case AUTH_REQ_OK:
			break;

		case AUTH_REQ_KRB4:
			printfPQExpBuffer(&conn->errorMessage,
				 libpq_gettext("Kerberos 4 authentication not supported\n"));
			return STATUS_ERROR;

		case AUTH_REQ_KRB5:
			printfPQExpBuffer(&conn->errorMessage,
				 libpq_gettext("Kerberos 5 authentication not supported\n"));
			return STATUS_ERROR;

#if defined(ENABLE_GSS) || defined(ENABLE_SSPI)
		case AUTH_REQ_GSS:
#if !defined(ENABLE_SSPI)
			/* no native SSPI, so use GSSAPI library for it */
		case AUTH_REQ_SSPI:
#endif
			{
				int			r;

				pglock_thread();

				/*
				 * If we have both GSS and SSPI support compiled in, use SSPI
				 * support by default. This is overridable by a connection
				 * string parameter. Note that when using SSPI we still leave
				 * the negotiate parameter off, since we want SSPI to use the
				 * GSSAPI kerberos protocol. For actual SSPI negotiate
				 * protocol, we use AUTH_REQ_SSPI.
				 */
#if defined(ENABLE_GSS) && defined(ENABLE_SSPI)
				if (conn->gsslib && (pg_strcasecmp(conn->gsslib, "gssapi") == 0))
					r = pg_GSS_startup(conn);
				else
					r = pg_SSPI_startup(conn, 0);
#elif defined(ENABLE_GSS) && !defined(ENABLE_SSPI)
				r = pg_GSS_startup(conn);
#elif !defined(ENABLE_GSS) && defined(ENABLE_SSPI)
				r = pg_SSPI_startup(conn, 0);
#endif
				if (r != STATUS_OK)
				{
					/* Error message already filled in. */
					pgunlock_thread();
					return STATUS_ERROR;
				}
				pgunlock_thread();
			}
			break;

		case AUTH_REQ_GSS_CONT:
			{
				int			r;

				pglock_thread();
#if defined(ENABLE_GSS) && defined(ENABLE_SSPI)
				if (conn->usesspi)
					r = pg_SSPI_continue(conn);
				else
					r = pg_GSS_continue(conn);
#elif defined(ENABLE_GSS) && !defined(ENABLE_SSPI)
				r = pg_GSS_continue(conn);
#elif !defined(ENABLE_GSS) && defined(ENABLE_SSPI)
				r = pg_SSPI_continue(conn);
#endif
				if (r != STATUS_OK)
				{
					/* Error message already filled in. */
					pgunlock_thread();
					return STATUS_ERROR;
				}
				pgunlock_thread();
			}
			break;
#else							/* defined(ENABLE_GSS) || defined(ENABLE_SSPI) */
			/* No GSSAPI *or* SSPI support */
		case AUTH_REQ_GSS:
		case AUTH_REQ_GSS_CONT:
			printfPQExpBuffer(&conn->errorMessage,
					 libpq_gettext("GSSAPI authentication not supported\n"));
			return STATUS_ERROR;
#endif   /* defined(ENABLE_GSS) || defined(ENABLE_SSPI) */

#ifdef ENABLE_SSPI
		case AUTH_REQ_SSPI:

			/*
			 * SSPI has it's own startup message so libpq can decide which
			 * method to use. Indicate to pg_SSPI_startup that we want SSPI
			 * negotiation instead of Kerberos.
			 */
			pglock_thread();
			if (pg_SSPI_startup(conn, 1) != STATUS_OK)
			{
				/* Error message already filled in. */
				pgunlock_thread();
				return STATUS_ERROR;
			}
			pgunlock_thread();
			break;
#else

			/*
			 * No SSPI support. However, if we have GSSAPI but not SSPI
			 * support, AUTH_REQ_SSPI will have been handled in the codepath
			 * for AUTH_REQ_GSSAPI above, so don't duplicate the case label in
			 * that case.
			 */
#if !defined(ENABLE_GSS)
		case AUTH_REQ_SSPI:
			printfPQExpBuffer(&conn->errorMessage,
					   libpq_gettext("SSPI authentication not supported\n"));
			return STATUS_ERROR;
#endif   /* !define(ENABLE_GSSAPI) */
#endif   /* ENABLE_SSPI */


		case AUTH_REQ_CRYPT:
			printfPQExpBuffer(&conn->errorMessage,
					  libpq_gettext("Crypt authentication not supported\n"));
			return STATUS_ERROR;

		case AUTH_REQ_MD5:
		case AUTH_REQ_PASSWORD:
			conn->password_needed = true;
			if (conn->pgpass == NULL || conn->pgpass[0] == '\0')
			{
				printfPQExpBuffer(&conn->errorMessage,
								  PQnoPasswordSupplied);
				return STATUS_ERROR;
			}
			if (pg_password_sendauth(conn, conn->pgpass, areq) != STATUS_OK)
			{
				printfPQExpBuffer(&conn->errorMessage,
					 "fe_sendauth: error sending password authentication\n");
				return STATUS_ERROR;
			}
			break;

		case AUTH_REQ_SASL:

			/*
			 * The request contains the name (as assigned by IANA) of the
			 * authentication mechanism.
			 */
			if (pg_SASL_init(conn, payloadlen) != STATUS_OK)
			{
				/* pg_SASL_init already set the error message */
				return STATUS_ERROR;
			}
			break;

		case AUTH_REQ_SASL_CONT:
		case AUTH_REQ_SASL_FIN:
			if (conn->sasl_state == NULL)
			{
				printfPQExpBuffer(&conn->errorMessage,
								  "fe_sendauth: invalid authentication request from server: AUTH_REQ_SASL_CONT without AUTH_REQ_SASL\n");
				return STATUS_ERROR;
			}
			if (pg_SASL_continue(conn, payloadlen,
								 (areq == AUTH_REQ_SASL_FIN)) != STATUS_OK)
			{
				/* Use error message, if set already */
				if (conn->errorMessage.len == 0)
					printfPQExpBuffer(&conn->errorMessage,
							  "fe_sendauth: error in SASL authentication\n");
				return STATUS_ERROR;
			}
			break;

		case AUTH_REQ_SCM_CREDS:
			if (pg_local_sendauth(conn) != STATUS_OK)
				return STATUS_ERROR;
			break;

		default:
			printfPQExpBuffer(&conn->errorMessage,
			libpq_gettext("authentication method %u not supported\n"), areq);
			return STATUS_ERROR;
	}

	return STATUS_OK;
}


/*
 * pg_fe_getauthname
 *
 * Returns a pointer to malloc'd space containing whatever name the user
 * has authenticated to the system.  If there is an error, return NULL,
 * and put a suitable error message in *errorMessage if that's not NULL.
 */
char *
pg_fe_getauthname(PQExpBuffer errorMessage)
{
	char	   *result = NULL;
	const char *name = NULL;

#ifdef WIN32
	/* Microsoft recommends buffer size of UNLEN+1, where UNLEN = 256 */
	char		username[256 + 1];
	DWORD		namesize = sizeof(username);
#else
	uid_t		user_id = geteuid();
	char		pwdbuf[BUFSIZ];
	struct passwd pwdstr;
	struct passwd *pw = NULL;
	int			pwerr;
#endif

	/*
	 * Some users are using configure --enable-thread-safety-force, so we
	 * might as well do the locking within our library to protect
	 * pqGetpwuid(). In fact, application developers can use getpwuid() in
	 * their application if they use the locking call we provide, or install
	 * their own locking function using PQregisterThreadLock().
	 */
	pglock_thread();

#ifdef WIN32
	if (GetUserName(username, &namesize))
		name = username;
	else if (errorMessage)
		printfPQExpBuffer(errorMessage,
				 libpq_gettext("user name lookup failure: error code %lu\n"),
						  GetLastError());
#else
	pwerr = pqGetpwuid(user_id, &pwdstr, pwdbuf, sizeof(pwdbuf), &pw);
	if (pw != NULL)
		name = pw->pw_name;
	else if (errorMessage)
	{
		if (pwerr != 0)
			printfPQExpBuffer(errorMessage,
				   libpq_gettext("could not look up local user ID %d: %s\n"),
							  (int) user_id,
							  pqStrerror(pwerr, pwdbuf, sizeof(pwdbuf)));
		else
			printfPQExpBuffer(errorMessage,
					 libpq_gettext("local user with ID %d does not exist\n"),
							  (int) user_id);
	}
#endif

	if (name)
	{
		result = strdup(name);
		if (result == NULL && errorMessage)
			printfPQExpBuffer(errorMessage,
							  libpq_gettext("out of memory\n"));
	}

	pgunlock_thread();

	return result;
}


/*
 * PQencryptPassword -- exported routine to encrypt a password with MD5
 *
 * This function is equivalent to calling PQencryptPasswordConn with
 * "md5" as the encryption method, except that this doesn't require
 * a connection object.  This function is deprecated, use
 * PQencryptPasswordConn instead.
 */
char *
PQencryptPassword(const char *passwd, const char *user)
{
	char	   *crypt_pwd;

	crypt_pwd = malloc(MD5_PASSWD_LEN + 1);
	if (!crypt_pwd)
		return NULL;

	if (!pg_md5_encrypt(passwd, user, strlen(user), crypt_pwd))
	{
		free(crypt_pwd);
		return NULL;
	}

	return crypt_pwd;
}

/*
 * PQencryptPasswordConn -- exported routine to encrypt a password
 *
 * This is intended to be used by client applications that wish to send
 * commands like ALTER USER joe PASSWORD 'pwd'.  The password need not
 * be sent in cleartext if it is encrypted on the client side.  This is
 * good because it ensures the cleartext password won't end up in logs,
 * pg_stat displays, etc.  We export the function so that clients won't
 * be dependent on low-level details like whether the encryption is MD5
 * or something else.
 *
 * Arguments are a connection object, the cleartext password, the SQL
 * name of the user it is for, and a string indicating the algorithm to
 * use for encrypting the password.  If algorithm is NULL, this queries
 * the server for the current 'password_encryption' value.  If you wish
 * to avoid that, e.g. to avoid blocking, you can execute
 * 'show password_encryption' yourself before calling this function, and
 * pass it as the algorithm.
 *
 * Return value is a malloc'd string.  The client may assume the string
 * doesn't contain any special characters that would require escaping.
 * On error, an error message is stored in the connection object, and
 * returns NULL.
 */
char *
PQencryptPasswordConn(PGconn *conn, const char *passwd, const char *user,
					  const char *algorithm)
{
#define MAX_ALGORITHM_NAME_LEN 50
	char		algobuf[MAX_ALGORITHM_NAME_LEN + 1];
	char	   *crypt_pwd = NULL;

	if (!conn)
		return NULL;

	/* If no algorithm was given, ask the server. */
	if (algorithm == NULL)
	{
		PGresult   *res;
		char	   *val;

		res = PQexec(conn, "show password_hash_algorithm");
		if (res == NULL)
		{
			/* PQexec() should've set conn->errorMessage already */
			return NULL;
		}
		if (PQresultStatus(res) != PGRES_TUPLES_OK)
		{
			/* PQexec() should've set conn->errorMessage already */
			PQclear(res);
			return NULL;
		}
		if (PQntuples(res) != 1 || PQnfields(res) != 1)
		{
			PQclear(res);
			printfPQExpBuffer(&conn->errorMessage,
							  libpq_gettext("unexpected shape of result set returned for SHOW\n"));
			return NULL;
		}
		val = PQgetvalue(res, 0, 0);

		if (strlen(val) > MAX_ALGORITHM_NAME_LEN)
		{
			PQclear(res);
			printfPQExpBuffer(&conn->errorMessage,
							  libpq_gettext("password_encryption value too long\n"));
			return NULL;
		}
		strcpy(algobuf, val);
		PQclear(res);

		algorithm = algobuf;
	}

	/* Ok, now we know what algorithm to use */

	if (strcmp(algorithm, "SCRAM-SHA-256") == 0)
	{
		crypt_pwd = pg_fe_scram_build_verifier(passwd);
	}
	else if (strcmp(algorithm, "MD5") == 0)
	{
		crypt_pwd = malloc(MD5_PASSWD_LEN + 1);
		if (crypt_pwd)
		{
			if (!pg_md5_encrypt(passwd, user, strlen(user), crypt_pwd))
			{
				free(crypt_pwd);
				crypt_pwd = NULL;
			}
		}
	}
	else if (strcmp(algorithm, "SHA-256") == 0)
	{
		crypt_pwd = malloc(SHA256_PASSWD_LEN + 1);
		if (!pg_sha256_encrypt(passwd, (char *) user, strlen(user), crypt_pwd))
		{
			free(crypt_pwd);
			crypt_pwd = NULL;
		}
	}
	else
	{
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("unknown password encryption algorithm\n"));
		return NULL;
	}

	if (!crypt_pwd)
		printfPQExpBuffer(&conn->errorMessage,
						  libpq_gettext("out of memory\n"));

	return crypt_pwd;
}
