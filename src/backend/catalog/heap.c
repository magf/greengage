/*-------------------------------------------------------------------------
 *
 * heap.c
 *	  code to create and destroy POSTGRES heap relations
 *
 * Portions Copyright (c) 2005-2010, Greenplum inc
 * Portions Copyright (c) 2012-Present Pivotal Software, Inc.
 * Portions Copyright (c) 1996-2014, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 *
 * IDENTIFICATION
 *	  src/backend/catalog/heap.c
 *
 *
 * INTERFACE ROUTINES
 *		heap_create()			- Create an uncataloged heap relation
 *		heap_create_with_catalog() - Create a cataloged relation
 *		heap_drop_with_catalog() - Removes named relation from catalogs
 *
 * NOTES
 *	  this code taken from access/heap/create.c, which contains
 *	  the old heap_create_with_catalog, amcreate, and amdestroy.
 *	  those routines will soon call these routines using the function
 *	  manager,
 *	  just like the poorly named "NewXXX" routines do.  The
 *	  "New" routines are all going to die soon, once and for all!
 *		-cim 1/13/91
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/aomd.h"
#include "access/htup_details.h"
#include "access/multixact.h"
#include "access/sysattr.h"
#include "access/transam.h"
#include "access/reloptions.h"
#include "access/xact.h"
#include "catalog/aocatalog.h"
#include "catalog/binary_upgrade.h"
#include "catalog/catalog.h"
#include "catalog/dependency.h"
#include "catalog/gp_policy.h"
#include "catalog/heap.h"
#include "catalog/index.h"
#include "catalog/namespace.h"
#include "catalog/objectaccess.h"
#include "catalog/oid_dispatch.h"
#include "catalog/pg_appendonly_fn.h"
#include "catalog/pg_attrdef.h"
#include "catalog/pg_attribute_encoding.h"
#include "catalog/pg_authid.h"
#include "catalog/pg_auth_members.h"
#include "catalog/pg_collation.h"
#include "catalog/pg_constraint.h"
#include "catalog/pg_database.h"
#include "catalog/pg_exttable.h"
#include "catalog/pg_foreign_table.h"
#include "catalog/pg_inherits.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_partition.h"
#include "catalog/pg_partition_rule.h"
#include "catalog/pg_statistic.h"
#include "catalog/pg_stat_last_operation.h"
#include "catalog/pg_stat_last_shoperation.h"
#include "catalog/pg_tablespace.h"
#include "catalog/pg_type.h"
#include "catalog/pg_type_fn.h"
#include "catalog/storage.h"
#include "catalog/storage_xlog.h"
#include "commands/tablecmds.h"
#include "commands/typecmds.h"
#include "miscadmin.h"
#include "nodes/nodeFuncs.h"
#include "optimizer/var.h"
#include "parser/parse_coerce.h"
#include "parser/parse_collate.h"
#include "parser/parse_expr.h"
#include "parser/parse_relation.h"
#include "storage/predicate.h"
#include "storage/smgr.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/inval.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"             /* CDB: GetMemoryChunkContext */
#include "utils/relcache.h"
#include "utils/rel.h"
#include "utils/snapmgr.h"
#include "utils/syscache.h"
#include "utils/tqual.h"
#include "utils/timestamp.h"

#include "cdb/cdbpartition.h"
#include "cdb/cdbsreh.h"
#include "cdb/cdbvars.h"

#include "utils/guc.h"


static void MetaTrackAddUpdInternal(Oid			classid,
									Oid			objoid,
									Oid			relowner,
									char*		actionname,
									char*		subtype,
									Relation	rel,
									HeapTuple	old_tuple);



/* Potentially set by contrib/pg_upgrade_support functions */
Oid			binary_upgrade_next_heap_pg_class_oid = InvalidOid;
Oid			binary_upgrade_next_toast_pg_class_oid = InvalidOid;

static void AddNewRelationTuple(Relation pg_class_desc,
					Relation new_rel_desc,
					Oid new_rel_oid,
					Oid new_type_oid,
					Oid reloftype,
					Oid relowner,
					char relkind,
					char relstorage,
					Datum relacl,
					Datum reloptions,
					bool is_part_parent);
static Oid AddNewRelationType(const char *typeName,
				   Oid typeNamespace,
				   Oid new_rel_oid,
				   char new_rel_kind,
				   Oid ownerid,
				   Oid new_row_type,
				   Oid new_array_type);
static void RelationRemoveInheritance(Oid relid);
static void StoreRelCheck(Relation rel, char *ccname, Node *expr,
			  bool is_validated, bool is_local, int inhcount,
			  bool is_no_inherit, bool is_internal);
static void StoreConstraints(Relation rel, List *cooked_constraints,
				 bool is_internal);
static bool MergeWithExistingConstraint(Relation rel, char *ccname, Node *expr,
							bool allow_merge, bool is_local,
							bool is_initially_valid,
							bool is_no_inherit);
static Node *cookConstraint(ParseState *pstate,
			   Node *raw_constraint,
			   char *relname);
static List *insert_ordered_unique_oid(List *list, Oid datum);


/* ----------------------------------------------------------------
 *				XXX UGLY HARD CODED BADNESS FOLLOWS XXX
 *
 *		these should all be moved to someplace in the lib/catalog
 *		module, if not obliterated first.
 * ----------------------------------------------------------------
 */


/*
 * Note:
 *		Should the system special case these attributes in the future?
 *		Advantage:	consume much less space in the ATTRIBUTE relation.
 *		Disadvantage:  special cases will be all over the place.
 */

/*
 * The initializers below do not include trailing variable length fields,
 * but that's OK - we're never going to reference anything beyond the
 * fixed-size portion of the structure anyway.
 */

static FormData_pg_attribute a1 = {
	0, {"ctid"}, TIDOID, 0, sizeof(ItemPointerData),
	SelfItemPointerAttributeNumber, 0, -1, -1,
	false, 'p', 's', true, false, false, true, 0
};

static FormData_pg_attribute a2 = {
	0, {"oid"}, OIDOID, 0, sizeof(Oid),
	ObjectIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

static FormData_pg_attribute a3 = {
	0, {"xmin"}, XIDOID, 0, sizeof(TransactionId),
	MinTransactionIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

static FormData_pg_attribute a4 = {
	0, {"cmin"}, CIDOID, 0, sizeof(CommandId),
	MinCommandIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

static FormData_pg_attribute a5 = {
	0, {"xmax"}, XIDOID, 0, sizeof(TransactionId),
	MaxTransactionIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

static FormData_pg_attribute a6 = {
	0, {"cmax"}, CIDOID, 0, sizeof(CommandId),
	MaxCommandIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

/*
 * We decided to call this attribute "tableoid" rather than say
 * "classoid" on the basis that in the future there may be more than one
 * table of a particular class/type. In any case table is still the word
 * used in SQL.
 */
static FormData_pg_attribute a7 = {
	0, {"tableoid"}, OIDOID, 0, sizeof(Oid),
	TableOidAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

/*CDB*/
static FormData_pg_attribute a8 = {
	0, {"gp_segment_id"}, INT4OID, 0, sizeof(gpsegmentId),
	GpSegmentIdAttributeNumber, 0, -1, -1,
	true, 'p', 'i', true, false, false, true, 0
};

static const Form_pg_attribute SysAtt[] = {&a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8};

/*
 * This function returns a Form_pg_attribute pointer for a system attribute.
 * Note that we elog if the presented attno is invalid, which would only
 * happen if there's a problem upstream.
 */
Form_pg_attribute
SystemAttributeDefinition(AttrNumber attno, bool relhasoids)
{
	if (attno >= 0 || attno < -(int) lengthof(SysAtt))
		elog(ERROR, "invalid system attribute number %d", attno);
	if (attno == ObjectIdAttributeNumber && !relhasoids)
		elog(ERROR, "invalid system attribute number %d", attno);
	return SysAtt[-attno - 1];
}

/*
 * If the given name is a system attribute name, return a Form_pg_attribute
 * pointer for a prototype definition.  If not, return NULL.
 */
Form_pg_attribute
SystemAttributeByName(const char *attname, bool relhasoids)
{
	int			j;

	for (j = 0; j < (int) lengthof(SysAtt); j++)
	{
		Form_pg_attribute att = SysAtt[j];

		if (relhasoids || att->attnum != ObjectIdAttributeNumber)
		{
			if (strcmp(NameStr(att->attname), attname) == 0)
				return att;
		}
	}

	return NULL;
}


/* ----------------------------------------------------------------
 *				XXX END OF UGLY HARD CODED BADNESS XXX
 * ---------------------------------------------------------------- */


/* ----------------------------------------------------------------
 *		heap_create		- Create an uncataloged heap relation
 *
 *		Note API change: the caller must now always provide the OID
 *		to use for the relation.  The relfilenode may (and, normally,
 *		should) be left unspecified.
 *
 *		rel->rd_rel is initialized by RelationBuildLocalRelation,
 *		and is mostly zeroes at return.
 * ----------------------------------------------------------------
 */
Relation
heap_create(const char *relname,
			Oid relnamespace,
			Oid reltablespace,
			Oid relid,
			Oid relfilenode,
			TupleDesc tupDesc,
			Oid relam,
			char relkind,
			char relpersistence,
			char relstorage,
			bool shared_relation,
			bool mapped_relation,
			bool allow_system_table_mods)
{
	bool		create_storage;
	Relation	rel;

	/* The caller must have provided an OID for the relation. */
	Assert(OidIsValid(relid));

	/*
	 * Don't allow creating relations in pg_catalog directly, even though it
	 * is allowed to move user defined relations there. Semantics with search
	 * paths including pg_catalog are too confusing for now.
	 *
	 * But allow creating indexes on relations in pg_catalog even if
	 * allow_system_table_mods = off, upper layers already guarantee it's on a
	 * user defined relation, not a system one.
	 */
	if (!allow_system_table_mods &&
		((IsSystemNamespace(relnamespace) && relkind != RELKIND_INDEX) ||
		 IsToastNamespace(relnamespace) ||
		 IsAoSegmentNamespace(relnamespace)) &&
		IsNormalProcessingMode())
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("permission denied to create \"%s.%s\"",
						get_namespace_name(relnamespace), relname),
		errdetail("System catalog modifications are currently disallowed.")));

	/*
	 * Decide if we need storage or not, and handle a couple other special
	 * cases for particular relkinds.
	 */
	switch (relkind)
	{
		case RELKIND_VIEW:
		case RELKIND_COMPOSITE_TYPE:
		case RELKIND_FOREIGN_TABLE:
			create_storage = false;

			/*
			 * Force reltablespace to zero if the relation has no physical
			 * storage.  This is mainly just for cleanliness' sake.
			 */
			reltablespace = InvalidOid;
			break;
		case RELKIND_SEQUENCE:
			create_storage = true;

			/*
			 * Force reltablespace to zero for sequences, since we don't
			 * support moving them around into different tablespaces.
			 */
			reltablespace = InvalidOid;
			break;
		default:
			if(relstorage_is_external(relstorage))
				create_storage = false;
			else
				create_storage = true;
			break;
	}

	/*
	 * Unless otherwise requested, the physical ID (relfilenode) is initially
	 * the same as the logical ID (OID).  When the caller did specify a
	 * relfilenode, it already exists; do not attempt to create it.
	 */
	if (OidIsValid(relfilenode))
		create_storage = false;
	else
		relfilenode = InvalidOid;

	/*
	 * Never allow a pg_class entry to explicitly specify the database's
	 * default tablespace in reltablespace; force it to zero instead. This
	 * ensures that if the database is cloned with a different default
	 * tablespace, the pg_class entry will still match where CREATE DATABASE
	 * will put the physically copied relation.
	 *
	 * Yes, this is a bit of a hack.
	 */
	if (reltablespace == MyDatabaseTableSpace)
		reltablespace = InvalidOid;

	/*
	 * build the relcache entry.
	 */
	rel = RelationBuildLocalRelation(relname,
									 relnamespace,
									 tupDesc,
									 relid,
									 relfilenode,
									 reltablespace,
									 shared_relation,
									 mapped_relation,
									 relpersistence,
									 relkind);

	/*
	 * Have the storage manager create the relation's disk file, if needed.
	 *
	 * We only create the main fork here, other forks will be created on
	 * demand.
	 */
	if (create_storage)
	{
		bool isAppendOnly;

		// WARNING: Do not use the rel structure -- it doesn't have relstorage set...
		isAppendOnly = (relstorage == RELSTORAGE_AOROWS || relstorage == RELSTORAGE_AOCOLS);

		RelationOpenSmgr(rel);
		RelationCreateStorage(rel->rd_node, relpersistence, relstorage);

		/*
		 * AO tables don't use the buffer manager, better to not keep the
		 * smgr open for it.
		 */
		if (isAppendOnly)
			RelationCloseSmgr(rel);
	}

	return rel;
}

/* ----------------------------------------------------------------
 *		heap_create_with_catalog		- Create a cataloged relation
 *
 *		this is done in multiple steps:
 *
 *		1) CheckAttributeNamesTypes() is used to make certain the tuple
 *		   descriptor contains a valid set of attribute names and types
 *
 *		2) pg_class is opened and get_relname_relid()
 *		   performs a scan to ensure that no relation with the
 *		   same name already exists.
 *
 *		3) heap_create() is called to create the new relation on disk.
 *
 *		4) TypeCreate() is called to define a new type corresponding
 *		   to the new relation.
 *
 *		5) AddNewRelationTuple() is called to register the
 *		   relation in pg_class.
 *
 *		6) AddNewAttributeTuples() is called to register the
 *		   new relation's schema in pg_attribute.
 *
 *		7) StoreConstraints is called ()		- vadim 08/22/97
 *
 *		8) the relations are closed and the new relation's oid
 *		   is returned.
 *
 * ----------------------------------------------------------------
 */

/* --------------------------------
 *		CheckAttributeNamesTypes
 *
 *		this is used to make certain the tuple descriptor contains a
 *		valid set of attribute names and datatypes.  a problem simply
 *		generates ereport(ERROR) which aborts the current transaction.
 * --------------------------------
 */
void
CheckAttributeNamesTypes(TupleDesc tupdesc, char relkind,
						 bool allow_system_table_mods)
{
	int			i;
	int			j;
	int			natts = tupdesc->natts;

	/* Sanity check on column count */
	if (natts < 0 || natts > MaxHeapAttributeNumber)
		ereport(ERROR,
				(errcode(ERRCODE_TOO_MANY_COLUMNS),
				 errmsg("tables can have at most %d columns",
						MaxHeapAttributeNumber)));

	/*
	 * first check for collision with system attribute names
	 *
	 * Skip this for a view or type relation, since those don't have system
	 * attributes.
	 */
	if (relkind != RELKIND_VIEW && relkind != RELKIND_COMPOSITE_TYPE)
	{
		for (i = 0; i < natts; i++)
		{
			if (SystemAttributeByName(NameStr(tupdesc->attrs[i]->attname),
									  tupdesc->tdhasoid) != NULL)
				ereport(ERROR,
						(errcode(ERRCODE_DUPLICATE_COLUMN),
						 errmsg("column name \"%s\" conflicts with a system column name",
								NameStr(tupdesc->attrs[i]->attname))));
		}
	}

	/*
	 * next check for repeated attribute names
	 */
	for (i = 1; i < natts; i++)
	{
		for (j = 0; j < i; j++)
		{
			if (strcmp(NameStr(tupdesc->attrs[j]->attname),
					   NameStr(tupdesc->attrs[i]->attname)) == 0)
				ereport(ERROR,
						(errcode(ERRCODE_DUPLICATE_COLUMN),
						 errmsg("column name \"%s\" specified more than once",
								NameStr(tupdesc->attrs[j]->attname))));
		}
	}

	/*
	 * next check the attribute types
	 */
	for (i = 0; i < natts; i++)
	{
		CheckAttributeType(NameStr(tupdesc->attrs[i]->attname),
						   tupdesc->attrs[i]->atttypid,
						   tupdesc->attrs[i]->attcollation,
						   NIL, /* assume we're creating a new rowtype */
						   allow_system_table_mods);
	}
}

/* --------------------------------
 *		CheckAttributeType
 *
 *		Verify that the proposed datatype of an attribute is legal.
 *		This is needed mainly because there are types (and pseudo-types)
 *		in the catalogs that we do not support as elements of real tuples.
 *		We also check some other properties required of a table column.
 *
 * If the attribute is being proposed for addition to an existing table or
 * composite type, pass a one-element list of the rowtype OID as
 * containing_rowtypes.  When checking a to-be-created rowtype, it's
 * sufficient to pass NIL, because there could not be any recursive reference
 * to a not-yet-existing rowtype.
 * --------------------------------
 */
void
CheckAttributeType(const char *attname,
				   Oid atttypid, Oid attcollation,
				   List *containing_rowtypes,
				   bool allow_system_table_mods)
{
	char		att_typtype = get_typtype(atttypid);
	Oid			att_typelem;

	if (Gp_role == GP_ROLE_EXECUTE)
	{
		/*
		 * In executor nodes, don't bother checking, as the dispatcher should've
		 * checked this already.
		 */
		return;
	}

	if (atttypid == UNKNOWNOID)
	{
		/*
		 * Warn user, but don't fail, if column to be created has UNKNOWN type
		 * (usually as a result of a 'retrieve into' - jolly)
		 */
		ereport(WARNING,
				(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
				 errmsg("column \"%s\" has type \"unknown\"", attname),
				 errdetail("Proceeding with relation creation anyway.")));
	}
	else if (att_typtype == TYPTYPE_PSEUDO)
	{
		/*
		 * Refuse any attempt to create a pseudo-type column, except for a
		 * special hack for pg_statistic: allow ANYARRAY when modifying system
		 * catalogs (this allows creating pg_statistic and cloning it during
		 * VACUUM FULL)
		 */
		if (atttypid != ANYARRAYOID || !allow_system_table_mods)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
					 errmsg("column \"%s\" has pseudo-type %s",
							attname, format_type_be(atttypid))));
	}
	else if (att_typtype == TYPTYPE_DOMAIN)
	{
		/*
		 * If it's a domain, recurse to check its base type.
		 */
		CheckAttributeType(attname, getBaseType(atttypid), attcollation,
						   containing_rowtypes,
						   allow_system_table_mods);
	}
	else if (att_typtype == TYPTYPE_COMPOSITE)
	{
		/*
		 * For a composite type, recurse into its attributes.
		 */
		Relation	relation;
		TupleDesc	tupdesc;
		int			i;

		/*
		 * Check for self-containment.  Eventually we might be able to allow
		 * this (just return without complaint, if so) but it's not clear how
		 * many other places would require anti-recursion defenses before it
		 * would be safe to allow tables to contain their own rowtype.
		 */
		if (list_member_oid(containing_rowtypes, atttypid))
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
				errmsg("composite type %s cannot be made a member of itself",
					   format_type_be(atttypid))));

		containing_rowtypes = lcons_oid(atttypid, containing_rowtypes);

		relation = relation_open(get_typ_typrelid(atttypid), AccessShareLock);

		tupdesc = RelationGetDescr(relation);

		for (i = 0; i < tupdesc->natts; i++)
		{
			Form_pg_attribute attr = tupdesc->attrs[i];

			if (attr->attisdropped)
				continue;
			CheckAttributeType(NameStr(attr->attname),
							   attr->atttypid, attr->attcollation,
							   containing_rowtypes,
							   allow_system_table_mods);
		}

		relation_close(relation, AccessShareLock);

		containing_rowtypes = list_delete_first(containing_rowtypes);
	}
	else if (att_typtype == TYPTYPE_RANGE)
	{
		/*
		 * If it's a range, recurse to check its subtype.
		 */
		CheckAttributeType(attname, get_range_subtype(atttypid),
						   get_range_collation(atttypid),
						   containing_rowtypes,
						   allow_system_table_mods);
	}
	else if (OidIsValid((att_typelem = get_element_type(atttypid))))
	{
		/*
		 * Must recurse into array types, too, in case they are composite.
		 */
		CheckAttributeType(attname, att_typelem, attcollation,
						   containing_rowtypes,
						   allow_system_table_mods);
	}

	/*
	 * This might not be strictly invalid per SQL standard, but it is pretty
	 * useless, and it cannot be dumped, so we must disallow it.
	 */
	if (!OidIsValid(attcollation) && type_is_collatable(atttypid))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TABLE_DEFINITION),
				 errmsg("no collation was derived for column \"%s\" with collatable type %s",
						attname, format_type_be(atttypid)),
		errhint("Use the COLLATE clause to set the collation explicitly.")));
}

/* MPP-6929: metadata tracking */
/* --------------------------------
 *		MetaTrackAddObject
 *
 *		Track creation of object in pg_stat_last_operation. The
 *		arguments are:
 *
 *		classid		- the oid of the table containing the object, eg
 *					  "pg_class" for a relation
 *		objoid		- the oid of the object itself in the specified table
 *		relowner	- role ? user ?
 *		actionname	- generally CREATE for this case
 *		subtype		- some generic descriptive, eg TABLE for a "CREATE TABLE"
 *
 *
 * --------------------------------
 */

static void MetaTrackAddUpdInternal(Oid			classid,
									Oid			objoid,
									Oid			relowner,
									char*		actionname,
									char*		subtype,
									Relation	rel,
									HeapTuple	old_tuple)
{
	HeapTuple	new_tuple;
	Datum		values[Natts_pg_statlastop];
	bool		isnull[Natts_pg_statlastop];
	bool		new_record_repl[Natts_pg_statlastop];
	NameData	uname;
	NameData	aname;
	HeapTuple	roletup;

	MemSet(isnull, 0, sizeof(bool) * Natts_pg_statlastop);
	MemSet(new_record_repl, 0, sizeof(bool) * Natts_pg_statlastop);

	values[Anum_pg_statlastop_classid - 1] = ObjectIdGetDatum(classid);
	values[Anum_pg_statlastop_objid - 1] = ObjectIdGetDatum(objoid);

	aname.data[0] = '\0';
	namestrcpy(&aname, actionname);
	values[Anum_pg_statlastop_staactionname - 1] = NameGetDatum(&aname);

	values[Anum_pg_statlastop_stasysid - 1] = ObjectIdGetDatum(relowner);
	/* set this column to update */
	new_record_repl[Anum_pg_statlastop_stasysid - 1] = true;

	uname.data[0] = '\0';

	roletup = SearchSysCache(AUTHOID,
							 ObjectIdGetDatum(relowner),
							 0, 0, 0);
	if (HeapTupleIsValid(roletup))
	{
		Form_pg_authid authid_tup = (Form_pg_authid) GETSTRUCT(roletup);

		namecpy(&uname, &authid_tup->rolname);
		ReleaseSysCache(roletup);
	}
	else
	{
		/* Generate numeric OID if we don't find an entry */
		sprintf(NameStr(uname), "%u", relowner);
	}

	values[Anum_pg_statlastop_stausename - 1] = NameGetDatum(&uname);
	/* set this column to update */
	new_record_repl[Anum_pg_statlastop_stausename - 1] = true;

	values[Anum_pg_statlastop_stasubtype - 1] = CStringGetTextDatum(subtype);
	/* set this column to update */
	new_record_repl[Anum_pg_statlastop_stasubtype - 1] = true;

	values[Anum_pg_statlastop_statime - 1] = GetCurrentTimestamp();
	/* set this column to update */
	new_record_repl[Anum_pg_statlastop_statime - 1] = true;

	if (HeapTupleIsValid(old_tuple))
	{
		new_tuple = heap_modify_tuple(old_tuple, RelationGetDescr(rel),
									  values,
									  isnull, new_record_repl);
		CatalogTupleUpdate(rel, &old_tuple->t_self, new_tuple);
	}
	else
	{
		new_tuple = heap_form_tuple(RelationGetDescr(rel), values, isnull);

		CatalogTupleInsert(rel, new_tuple);
	}

	if (HeapTupleIsValid(old_tuple))
		heap_freetuple(new_tuple);

} /* end MetaTrackAddUpdInternal */


void MetaTrackAddObject(Oid		classid, 
						Oid		objoid, 
						Oid		relowner,
						char*	actionname,
						char*	subtype)
{
	Relation	rel;

	if (IsBootstrapProcessingMode())
		return;

	if (IsSharedRelation(classid))
	{
		rel = heap_open(StatLastShOpRelationId, RowExclusiveLock);
	}
	else
	{
		rel = heap_open(StatLastOpRelationId, RowExclusiveLock);
	}

	MetaTrackAddUpdInternal(classid, objoid, relowner,
							actionname, subtype,
							rel, NULL);

	heap_close(rel, RowExclusiveLock);

/*	CommandCounterIncrement(); */

} /* end MetaTrackAddObject */

void MetaTrackUpdObject(Oid		classid, 
						Oid		objoid, 
						Oid		relowner,
						char*	actionname,
						char*	subtype)
{
	HeapTuple	tuple;
	ScanKeyData key[3];
	SysScanDesc desc;
	Relation	rel;
	int			ii = 0;

	if (IsBootstrapProcessingMode())
		return;

	if (IsSharedRelation(classid))
	{
		rel = heap_open(StatLastShOpRelationId, RowExclusiveLock);

		ScanKeyInit(&key[0],
					Anum_pg_statlastshop_classid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(classid));
		ScanKeyInit(&key[1],
					Anum_pg_statlastshop_objid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(objoid));
		ScanKeyInit(&key[2],
					Anum_pg_statlastshop_staactionname,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(actionname));

		desc = systable_beginscan(rel,
								  StatLastShOpClassidObjidStaactionnameIndexId,
								  true,
								  NULL, 3, key);
	}
	else
	{
		rel = heap_open(StatLastOpRelationId, RowExclusiveLock);

		ScanKeyInit(&key[0],
					Anum_pg_statlastop_classid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(classid));
		ScanKeyInit(&key[1],
					Anum_pg_statlastop_objid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(objoid));
		ScanKeyInit(&key[2],
					Anum_pg_statlastop_staactionname,
					BTEqualStrategyNumber, F_NAMEEQ,
					CStringGetDatum(actionname));

		desc = systable_beginscan(rel,
								  StatLastOpClassidObjidStaactionnameIndexId,
								  true,
								  NULL, 3, key);
	}

	/* should be a unique index - only 1 answer... */
	while (HeapTupleIsValid(tuple = systable_getnext(desc)))
	{
		MetaTrackAddUpdInternal(classid, objoid, relowner,
								actionname, subtype,
								rel, tuple);
		ii++;
	}
	systable_endscan(desc);
	heap_close(rel, RowExclusiveLock);

	/* add it if it didn't already exist */
	if (!ii)
		MetaTrackAddObject(classid, 
						   objoid, 
						   relowner,
						   actionname,
						   subtype);

} /* end MetaTrackUpdObject */
void MetaTrackDropObject(Oid		classid, 
						 Oid		objoid)
{
	HeapTuple	tuple;
	ScanKeyData key[3];
	SysScanDesc desc;
	Relation	rel;

	if (IsSharedRelation(classid))
	{
		/* DELETE FROM pg_stat_last_shoperation WHERE classid = :1 AND objid = :2 */

		rel = heap_open(StatLastShOpRelationId, RowExclusiveLock);

		ScanKeyInit(&key[0],
					Anum_pg_statlastshop_classid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(classid));
		ScanKeyInit(&key[1],
					Anum_pg_statlastshop_objid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(objoid));

		desc = systable_beginscan(rel,
								  StatLastShOpClassidObjidStaactionnameIndexId,
								  true,
								  NULL, 2, key);
	}
	else
	{
		/* DELETE FROM pg_stat_last_operation WHERE classid = :1 AND objid = :2 */
		rel = heap_open(StatLastOpRelationId, RowExclusiveLock);

		ScanKeyInit(&key[0],
					Anum_pg_statlastop_classid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(classid));
		ScanKeyInit(&key[1],
					Anum_pg_statlastop_objid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(objoid));

		desc = systable_beginscan(rel,
								  StatLastOpClassidObjidStaactionnameIndexId,
								  true,
								  NULL, 2, key);
	}

	while (HeapTupleIsValid(tuple = systable_getnext(desc)))
		CatalogTupleDelete(rel, &tuple->t_self);

	systable_endscan(desc);
	heap_close(rel, RowExclusiveLock);

} /* end MetaTrackDropObject */

/*
 * InsertPgAttributeTuple
 *		Construct and insert a new tuple in pg_attribute.
 *
 * Caller has already opened and locked pg_attribute.  new_attribute is the
 * attribute to insert (but we ignore attacl and attoptions, which are always
 * initialized to NULL).
 *
 * indstate is the index state for CatalogTupleInsertWithInfo.  It can be
 * passed as NULL, in which case we'll fetch the necessary info.  (Don't do
 * this when inserting multiple attributes, because it's a tad more
 * expensive.)
 */
void
InsertPgAttributeTuple(Relation pg_attribute_rel,
					   Form_pg_attribute new_attribute,
					   CatalogIndexState indstate)
{
	Datum		values[Natts_pg_attribute];
	bool		nulls[Natts_pg_attribute];
	HeapTuple	tup;

	/* This is a tad tedious, but way cleaner than what we used to do... */
	memset(values, 0, sizeof(values));
	memset(nulls, false, sizeof(nulls));

	values[Anum_pg_attribute_attrelid - 1] = ObjectIdGetDatum(new_attribute->attrelid);
	values[Anum_pg_attribute_attname - 1] = NameGetDatum(&new_attribute->attname);
	values[Anum_pg_attribute_atttypid - 1] = ObjectIdGetDatum(new_attribute->atttypid);
	values[Anum_pg_attribute_attstattarget - 1] = Int32GetDatum(new_attribute->attstattarget);
	values[Anum_pg_attribute_attlen - 1] = Int16GetDatum(new_attribute->attlen);
	values[Anum_pg_attribute_attnum - 1] = Int16GetDatum(new_attribute->attnum);
	values[Anum_pg_attribute_attndims - 1] = Int32GetDatum(new_attribute->attndims);
	values[Anum_pg_attribute_attcacheoff - 1] = Int32GetDatum(new_attribute->attcacheoff);
	values[Anum_pg_attribute_atttypmod - 1] = Int32GetDatum(new_attribute->atttypmod);
	values[Anum_pg_attribute_attbyval - 1] = BoolGetDatum(new_attribute->attbyval);
	values[Anum_pg_attribute_attstorage - 1] = CharGetDatum(new_attribute->attstorage);
	values[Anum_pg_attribute_attalign - 1] = CharGetDatum(new_attribute->attalign);
	values[Anum_pg_attribute_attnotnull - 1] = BoolGetDatum(new_attribute->attnotnull);
	values[Anum_pg_attribute_atthasdef - 1] = BoolGetDatum(new_attribute->atthasdef);
	values[Anum_pg_attribute_attisdropped - 1] = BoolGetDatum(new_attribute->attisdropped);
	values[Anum_pg_attribute_attislocal - 1] = BoolGetDatum(new_attribute->attislocal);
	values[Anum_pg_attribute_attinhcount - 1] = Int32GetDatum(new_attribute->attinhcount);
	values[Anum_pg_attribute_attcollation - 1] = ObjectIdGetDatum(new_attribute->attcollation);

	/* start out with empty permissions and empty options */
	nulls[Anum_pg_attribute_attacl - 1] = true;
	nulls[Anum_pg_attribute_attoptions - 1] = true;
	nulls[Anum_pg_attribute_attfdwoptions - 1] = true;

	tup = heap_form_tuple(RelationGetDescr(pg_attribute_rel), values, nulls);

	/* finally insert the new tuple, update the indexes, and clean up */
	if (indstate != NULL)
		CatalogTupleInsertWithInfo(pg_attribute_rel, tup, indstate);
	else
		CatalogTupleInsert(pg_attribute_rel, tup);

	heap_freetuple(tup);
}

/* --------------------------------
 *		AddNewAttributeTuples
 *
 *		this registers the new relation's schema by adding
 *		tuples to pg_attribute.
 * --------------------------------
 */
static void
AddNewAttributeTuples(Oid new_rel_oid,
					  TupleDesc tupdesc,
					  char relkind,
					  bool oidislocal,
					  int oidinhcount)
{
	Form_pg_attribute attr;
	int			i;
	Relation	rel;
	CatalogIndexState indstate;
	int			natts = tupdesc->natts;
	ObjectAddress myself,
				referenced;

	/*
	 * open pg_attribute and its indexes.
	 */
	rel = heap_open(AttributeRelationId, RowExclusiveLock);

	indstate = CatalogOpenIndexes(rel);

	/*
	 * First we add the user attributes.  This is also a convenient place to
	 * add dependencies on their datatypes and collations.
	 */
	for (i = 0; i < natts; i++)
	{
		attr = tupdesc->attrs[i];
		/* Fill in the correct relation OID */
		attr->attrelid = new_rel_oid;
		/* Make sure these are OK, too */
		attr->attstattarget = -1;
		attr->attcacheoff = -1;

		InsertPgAttributeTuple(rel, attr, indstate);

		/* Add dependency info */
		myself.classId = RelationRelationId;
		myself.objectId = new_rel_oid;
		myself.objectSubId = i + 1;
		referenced.classId = TypeRelationId;
		referenced.objectId = attr->atttypid;
		referenced.objectSubId = 0;
		recordDependencyOn(&myself, &referenced, DEPENDENCY_NORMAL);

		/* The default collation is pinned, so don't bother recording it */
		if (OidIsValid(attr->attcollation) &&
			attr->attcollation != DEFAULT_COLLATION_OID)
		{
			referenced.classId = CollationRelationId;
			referenced.objectId = attr->attcollation;
			referenced.objectSubId = 0;
			recordDependencyOn(&myself, &referenced, DEPENDENCY_NORMAL);
		}
	}

	/*
	 * Next we add the system attributes.  Skip OID if rel has no OIDs. Skip
	 * all for a view or type relation.  We don't bother with making datatype
	 * dependencies here, since presumably all these types are pinned.
	 */
	if (relkind != RELKIND_VIEW && relkind != RELKIND_COMPOSITE_TYPE)
	{
		for (i = 0; i < (int) lengthof(SysAtt); i++)
		{
			FormData_pg_attribute attStruct;

			/* skip OID where appropriate */
			if (!tupdesc->tdhasoid &&
				SysAtt[i]->attnum == ObjectIdAttributeNumber)
				continue;

			memcpy(&attStruct, (char *) SysAtt[i], sizeof(FormData_pg_attribute));

			/* Fill in the correct relation OID in the copied tuple */
			attStruct.attrelid = new_rel_oid;

			/* Fill in correct inheritance info for the OID column */
			if (attStruct.attnum == ObjectIdAttributeNumber)
			{
				attStruct.attislocal = oidislocal;
				attStruct.attinhcount = oidinhcount;
			}

			InsertPgAttributeTuple(rel, &attStruct, indstate);
		}
	}

	/*
	 * clean up
	 */
	CatalogCloseIndexes(indstate);

	heap_close(rel, RowExclusiveLock);
}

/* --------------------------------
 *		InsertPgClassTuple
 *
 *		Construct and insert a new tuple in pg_class.
 *
 * Caller has already opened and locked pg_class.
 * Tuple data is taken from new_rel_desc->rd_rel, except for the
 * variable-width fields which are not present in a cached reldesc.
 * relacl and reloptions are passed in Datum form (to avoid having
 * to reference the data types in heap.h).  Pass (Datum) 0 to set them
 * to NULL.
 * --------------------------------
 */
void
InsertPgClassTuple(Relation pg_class_desc,
				   Relation new_rel_desc,
				   Oid new_rel_oid,
				   Datum relacl,
				   Datum reloptions)
{
	Form_pg_class rd_rel = new_rel_desc->rd_rel;
	Datum		values[Natts_pg_class];
	bool		nulls[Natts_pg_class];
	HeapTuple	tup;

	/* This is a tad tedious, but way cleaner than what we used to do... */
	memset(values, 0, sizeof(values));
	memset(nulls, false, sizeof(nulls));

	values[Anum_pg_class_relname - 1] = NameGetDatum(&rd_rel->relname);
	values[Anum_pg_class_relnamespace - 1] = ObjectIdGetDatum(rd_rel->relnamespace);
	values[Anum_pg_class_reltype - 1] = ObjectIdGetDatum(rd_rel->reltype);
	values[Anum_pg_class_reloftype - 1] = ObjectIdGetDatum(rd_rel->reloftype);
	values[Anum_pg_class_relowner - 1] = ObjectIdGetDatum(rd_rel->relowner);
	values[Anum_pg_class_relam - 1] = ObjectIdGetDatum(rd_rel->relam);
	values[Anum_pg_class_relfilenode - 1] = ObjectIdGetDatum(rd_rel->relfilenode);
	values[Anum_pg_class_reltablespace - 1] = ObjectIdGetDatum(rd_rel->reltablespace);
	values[Anum_pg_class_relpages - 1] = Int32GetDatum(rd_rel->relpages);
	values[Anum_pg_class_reltuples - 1] = Float4GetDatum(rd_rel->reltuples);
	values[Anum_pg_class_relallvisible - 1] = Int32GetDatum(rd_rel->relallvisible);
	values[Anum_pg_class_reltoastrelid - 1] = ObjectIdGetDatum(rd_rel->reltoastrelid);
	values[Anum_pg_class_relhasindex - 1] = BoolGetDatum(rd_rel->relhasindex);
	values[Anum_pg_class_relisshared - 1] = BoolGetDatum(rd_rel->relisshared);
	values[Anum_pg_class_relpersistence - 1] = CharGetDatum(rd_rel->relpersistence);
	values[Anum_pg_class_relkind - 1] = CharGetDatum(rd_rel->relkind);
	values[Anum_pg_class_relstorage - 1] = CharGetDatum(rd_rel->relstorage);
	values[Anum_pg_class_relnatts - 1] = Int16GetDatum(rd_rel->relnatts);
	values[Anum_pg_class_relchecks - 1] = Int16GetDatum(rd_rel->relchecks);
	values[Anum_pg_class_relhasoids - 1] = BoolGetDatum(rd_rel->relhasoids);
	values[Anum_pg_class_relhaspkey - 1] = BoolGetDatum(rd_rel->relhaspkey);
	values[Anum_pg_class_relhasrules - 1] = BoolGetDatum(rd_rel->relhasrules);
	values[Anum_pg_class_relhastriggers - 1] = BoolGetDatum(rd_rel->relhastriggers);
	values[Anum_pg_class_relhassubclass - 1] = BoolGetDatum(rd_rel->relhassubclass);
	values[Anum_pg_class_relispopulated - 1] = BoolGetDatum(rd_rel->relispopulated);
	values[Anum_pg_class_relreplident - 1] = CharGetDatum(rd_rel->relreplident);
	values[Anum_pg_class_relfrozenxid - 1] = TransactionIdGetDatum(rd_rel->relfrozenxid);
	values[Anum_pg_class_relminmxid - 1] = MultiXactIdGetDatum(rd_rel->relminmxid);
	if (relacl != (Datum) 0)
		values[Anum_pg_class_relacl - 1] = relacl;
	else
		nulls[Anum_pg_class_relacl - 1] = true;
	if (reloptions != (Datum) 0)
		values[Anum_pg_class_reloptions - 1] = reloptions;
	else
		nulls[Anum_pg_class_reloptions - 1] = true;

	tup = heap_form_tuple(RelationGetDescr(pg_class_desc), values, nulls);

	/*
	 * The new tuple must have the oid already chosen for the rel.  Sure would
	 * be embarrassing to do this sort of thing in polite company.
	 */
	HeapTupleSetOid(tup, new_rel_oid);

	/* finally insert the new tuple, update the indexes, and clean up */
	CatalogTupleInsert(pg_class_desc, tup);

	heap_freetuple(tup);
}

/* --------------------------------
 *		AddNewRelationTuple
 *
 *		this registers the new relation in the catalogs by
 *		adding a tuple to pg_class.
 * --------------------------------
 */
static void
AddNewRelationTuple(Relation pg_class_desc,
					Relation new_rel_desc,
					Oid new_rel_oid,
					Oid new_type_oid,
					Oid reloftype,
					Oid relowner,
					char relkind,
					char relstorage,
					Datum relacl,
					Datum reloptions,
					bool is_part_parent)
{
	Form_pg_class new_rel_reltup;

	/*
	 * first we update some of the information in our uncataloged relation's
	 * relation descriptor.
	 */
	new_rel_reltup = new_rel_desc->rd_rel;

	switch (relkind)
	{
		case RELKIND_RELATION:
		case RELKIND_MATVIEW:
		case RELKIND_INDEX:
		case RELKIND_TOASTVALUE:
		case RELKIND_AOSEGMENTS:
		case RELKIND_AOBLOCKDIR:
		case RELKIND_AOVISIMAP:
			/* The relation is real, but as yet empty */
			new_rel_reltup->relpages = 0;
			new_rel_reltup->reltuples = 0;

			/* estimated stats for external tables */
			/* NOTE: look at cdb_estimate_rel_size() if changing these values */
			if(relstorage_is_external(relstorage))
			{
				new_rel_reltup->relpages = 1000;
				new_rel_reltup->reltuples = 1000000;
			}
			new_rel_reltup->relallvisible = 0;
			break;
		case RELKIND_SEQUENCE:
			/* Sequences always have a known size */
			new_rel_reltup->relpages = 1;
			new_rel_reltup->reltuples = 1;
			new_rel_reltup->relallvisible = 0;
			break;
		default:
			/* Views, etc, have no disk storage */
			new_rel_reltup->relpages = 0;
			new_rel_reltup->reltuples = 0;
			new_rel_reltup->relallvisible = 0;
			break;
	}

	/* Initialize relfrozenxid and relminmxid */
	if (should_have_valid_relfrozenxid(relkind, relstorage, is_part_parent))
	{
		/*
		 * Initialize to the minimum XID that could put tuples in the table.
		 * We know that no xacts older than RecentXmin are still running, so
		 * that will do.
		 */
		new_rel_reltup->relfrozenxid = RecentXmin;

		/*
		 * Similarly, initialize the minimum Multixact to the first value that
		 * could possibly be stored in tuples in the table.  Running
		 * transactions could reuse values from their local cache, so we are
		 * careful to consider all currently running multis.
		 *
		 * XXX this could be refined further, but is it worth the hassle?
		 */
		new_rel_reltup->relminmxid = GetOldestMultiXactId();
	}
	else
	{
		/*
		 * Other relation types will not contain XIDs, so set relfrozenxid to
		 * InvalidTransactionId.  (Note: a sequence does contain a tuple, but
		 * we force its xmin to be FrozenTransactionId always; see
		 * commands/sequence.c.)
		 */
		new_rel_reltup->relfrozenxid = InvalidTransactionId;
		new_rel_reltup->relminmxid = InvalidMultiXactId;
	}

	new_rel_reltup->relowner = relowner;
	new_rel_reltup->reltype = new_type_oid;
	new_rel_reltup->reloftype = reloftype;
	new_rel_reltup->relkind = relkind;
	new_rel_reltup->relstorage = relstorage;

	new_rel_desc->rd_att->tdtypeid = new_type_oid;

	/* Now build and insert the tuple */
	InsertPgClassTuple(pg_class_desc, new_rel_desc, new_rel_oid,
					   relacl, reloptions);
}


/* --------------------------------
 *		AddNewRelationType -
 *
 *		define a composite type corresponding to the new relation
 * --------------------------------
 */
static Oid
AddNewRelationType(const char *typeName,
				   Oid typeNamespace,
				   Oid new_rel_oid,
				   char new_rel_kind,
				   Oid ownerid,
				   Oid new_row_type,
				   Oid new_array_type)
{
	return
		TypeCreate(new_row_type,	/* optional predetermined OID */
				   typeName,	/* type name */
				   typeNamespace,		/* type namespace */
				   new_rel_oid, /* relation oid */
				   new_rel_kind,	/* relation kind */
				   ownerid,		/* owner's ID */
				   -1,			/* internal size (varlena) */
				   TYPTYPE_COMPOSITE,	/* type-type (composite) */
				   TYPCATEGORY_COMPOSITE,		/* type-category (ditto) */
				   false,		/* composite types are never preferred */
				   DEFAULT_TYPDELIM,	/* default array delimiter */
				   F_RECORD_IN, /* input procedure */
				   F_RECORD_OUT,	/* output procedure */
				   F_RECORD_RECV,		/* receive procedure */
				   F_RECORD_SEND,		/* send procedure */
				   InvalidOid,	/* typmodin procedure - none */
				   InvalidOid,	/* typmodout procedure - none */
				   InvalidOid,	/* analyze procedure - default */
				   InvalidOid,	/* array element type - irrelevant */
				   false,		/* this is not an array type */
				   new_array_type,		/* array type if any */
				   InvalidOid,	/* domain base type - irrelevant */
				   NULL,		/* default value - none */
				   NULL,		/* default binary representation */
				   false,		/* passed by reference */
				   'd',			/* alignment - must be the largest! */
				   'x',			/* fully TOASTable */
				   -1,			/* typmod */
				   0,			/* array dimensions for typBaseType */
				   false,		/* Type NOT NULL */
				   InvalidOid); /* rowtypes never have a collation */
}

/* --------------------------------
 *		heap_create_with_catalog
 *
 *		creates a new cataloged relation.  see comments above.
 *
 * Arguments:
 *	relname: name to give to new rel
 *	relnamespace: OID of namespace it goes in
 *	reltablespace: OID of tablespace it goes in
 *	relid: OID to assign to new rel, or InvalidOid to select a new OID
 *	reltypeid: OID to assign to rel's rowtype, or InvalidOid to select one
 *	reloftypeid: if a typed table, OID of underlying type; else InvalidOid
 *	ownerid: OID of new rel's owner
 *	tupdesc: tuple descriptor (source of column definitions)
 *	cooked_constraints: list of precooked check constraints and defaults
 *	relkind: relkind for new rel
 *	relpersistence: rel's persistence status (permanent, temp, or unlogged)
 *	shared_relation: TRUE if it's to be a shared relation
 *	mapped_relation: TRUE if the relation will use the relfilenode map
 *	oidislocal: TRUE if oid column (if any) should be marked attislocal
 *	oidinhcount: attinhcount to assign to oid column (if any)
 *	oncommit: ON COMMIT marking (only relevant if it's a temp table)
 *	reloptions: reloptions in Datum form, or (Datum) 0 if none
 *	use_user_acl: TRUE if should look for user-defined default permissions;
 *		if FALSE, relacl is always set NULL
 *	allow_system_table_mods: TRUE to allow creation in system namespaces
 *	is_internal: is this a system-generated catalog?
 *  valid_opts: Validate the reloptions or not?
 *  is_part_child: TRUE if relation is a child partition
 *  is_part_parent: TRUE if relation is a parent partition
 *
 * Returns the OID of the new relation
 * --------------------------------
 */
Oid
heap_create_with_catalog(const char *relname,
						 Oid relnamespace,
						 Oid reltablespace,
						 Oid relid,
						 Oid reltypeid,
						 Oid reloftypeid,
						 Oid ownerid,
						 TupleDesc tupdesc,
						 List *cooked_constraints,
						 Oid relam,
						 char relkind,
						 char relpersistence,
						 char relstorage,
						 bool shared_relation,
						 bool mapped_relation,
						 bool oidislocal,
						 int oidinhcount,
						 OnCommitAction oncommit,
                         const struct GpPolicy *policy,
						 Datum reloptions,
						 bool use_user_acl,
						 bool allow_system_table_mods,
						 bool is_internal,
						 bool valid_opts,
						 bool is_part_child,
						 bool is_part_parent)
{
	Relation	pg_class_desc;
	Relation	new_rel_desc;
	Acl		   *relacl;
	Oid			existing_relid;
	Oid			old_type_oid;
	Oid			new_type_oid;
	Oid			new_array_oid = InvalidOid;
	bool		appendOnlyRel;
	StdRdOptions *stdRdOptions;
	int			safefswritesize = gp_safefswritesize;
	char	   *relarrayname = NULL;

	pg_class_desc = heap_open(RelationRelationId, RowExclusiveLock);

	/*
	 * sanity checks
	 */
	Assert(IsNormalProcessingMode() || IsBootstrapProcessingMode());

	/*
	 * Was "appendonly" specified in the relopts? If yes, fix our relstorage.
	 * Also, check for override (debug) GUCs.
	 */
	if (relkind == RELKIND_RELATION || relkind == RELKIND_MATVIEW)
	{
		stdRdOptions = (StdRdOptions*) heap_reloptions(
			relkind, reloptions, !valid_opts);
		appendOnlyRel = stdRdOptions->appendonly;
		validateAppendOnlyRelOptions(appendOnlyRel,
									 stdRdOptions->blocksize,
									 safefswritesize,
									 stdRdOptions->compresslevel,
									 stdRdOptions->compresstype,
									 stdRdOptions->checksum,
									 relkind,
									 stdRdOptions->columnstore);
		if(appendOnlyRel)
		{
			if(stdRdOptions->columnstore)
				relstorage = RELSTORAGE_AOCOLS;
			else
				relstorage = RELSTORAGE_AOROWS;
			reloptions = transformAOStdRdOptions(stdRdOptions, reloptions);
		}
	}
	else
	{
		appendOnlyRel = false;
		stdRdOptions = NULL;
	}

	/*
	 * MPP-8058: disallow OIDS on column-oriented tables.
	 */
	if (tupdesc->tdhasoid && relstorage == RELSTORAGE_AOCOLS)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("OIDS=TRUE is not allowed on tables that use column-oriented storage. Use OIDS=FALSE")));

	CheckAttributeNamesTypes(tupdesc, relkind, allow_system_table_mods);

	/*
	 * This would fail later on anyway, if the relation already exists.  But
	 * by catching it here we can emit a nicer error message.
	 */
	existing_relid = get_relname_relid(relname, relnamespace);
	if (existing_relid != InvalidOid)
		ereport(ERROR,
				(errcode(ERRCODE_DUPLICATE_TABLE),
				 errmsg("relation \"%s\" already exists", relname)));

	/*
	 * Since we are going to create a rowtype as well, also check for
	 * collision with an existing type name.  If there is one and it's an
	 * autogenerated array, we can rename it out of the way; otherwise we can
	 * at least give a good error message.
	 */
	old_type_oid = GetSysCacheOid2(TYPENAMENSP,
								   CStringGetDatum(relname),
								   ObjectIdGetDatum(relnamespace));
	if (OidIsValid(old_type_oid))
	{
		if (!moveArrayTypeName(old_type_oid, relname, relnamespace))
			ereport(ERROR,
					(errcode(ERRCODE_DUPLICATE_OBJECT),
					 errmsg("type \"%s\" already exists", relname),
			   errhint("A relation has an associated type of the same name, "
					   "so you must use a name that doesn't conflict "
					   "with any existing type.")));
	}

	/*
	 * Shared relations must be in pg_global (last-ditch check)
	 */
	if (shared_relation && reltablespace != GLOBALTABLESPACE_OID)
		elog(ERROR, "shared relations must be placed in pg_global tablespace");

	/*
	 * Get preassigned OID for GP_ROLE_EXECUTE or binary upgrade
	 */
	if (!OidIsValid(relid) && (Gp_role == GP_ROLE_EXECUTE || IsBinaryUpgrade))
		relid = GetPreassignedOidForRelation(relnamespace, relname);

	/*
	 * GP_ROLE_DISPATCH and GP_ROLE_UTILITY do not have preassigned OIDs.
	 * Allocate new OIDs here.
	 */
	if (!OidIsValid(relid) && Gp_role != GP_ROLE_EXECUTE)
		relid = GetNewOid(pg_class_desc);

	/*
	 * Determine the relation's initial permissions.
	 * If rel is partition child, leave it NULL here, Because CopyRelationAcls()
	 * will copy relacl from parent later.
	 */
	if (use_user_acl && !is_part_child)
	{
		switch (relkind)
		{
			case RELKIND_RELATION:
			case RELKIND_VIEW:
			case RELKIND_MATVIEW:
			case RELKIND_FOREIGN_TABLE:
				relacl = get_user_default_acl(ACL_OBJECT_RELATION, ownerid,
											  relnamespace);
				break;
			case RELKIND_SEQUENCE:
				relacl = get_user_default_acl(ACL_OBJECT_SEQUENCE, ownerid,
											  relnamespace);
				break;
			default:
				relacl = NULL;
				break;
		}
	}
	else
		relacl = NULL;

	/*
	 * Create the relcache entry (mostly dummy at this point) and the physical
	 * disk file.  (If we fail further down, it's the smgr's responsibility to
	 * remove the disk file again.)
	 */
	new_rel_desc = heap_create(relname,
							   relnamespace,
							   reltablespace,
							   relid,
							   InvalidOid,
							   tupdesc,
							   relam,
							   relkind,
							   relpersistence,
							   relstorage,
							   shared_relation,
							   mapped_relation,
							   allow_system_table_mods);

	Assert(relid == RelationGetRelid(new_rel_desc));

	/*
	 * Decide whether to create an array type over the relation's rowtype. We
	 * do not create any array types for system catalogs (ie, those made
	 * during initdb). We do not create them where the use of a relation as
	 * such is an implementation detail: toast tables, sequences and indexes.
	 *
	 * Also not for the auxiliary heaps created for bitmap indexes or append-
	 * only tables.
	 *
	 * In Greengage, we do not create an array type for child
	 * partitions. Child partitions are automatically named very similarly
	 * which can cause typname collisions very easily. If there are a lot of
	 * typname collisions, it's possible that makeArrayTypeName could fail to
	 * create a typname and error us out.
	 */
	if (IsUnderPostmaster && ((relkind == RELKIND_RELATION && !appendOnlyRel) ||
							  relkind == RELKIND_VIEW ||
							  relkind == RELKIND_MATVIEW ||
							  relkind == RELKIND_FOREIGN_TABLE ||
							  relkind == RELKIND_COMPOSITE_TYPE) &&
		relnamespace != PG_BITMAPINDEX_NAMESPACE &&
		!is_part_child)
	{
		/* OK, so pre-assign a type OID for the array type */
		Relation	pg_type = heap_open(TypeRelationId, AccessShareLock);

		relarrayname = makeArrayTypeName(relname, relnamespace);

		/*
		 * If we are expected to get a preassigned Oid but receive InvalidOid,
		 * get a new Oid. This can happen during upgrades from GPDB4 to 5 where
		 * array types over relation rowtypes were introduced so there are no
		 * pre-existing array types to dump from the old cluster
		 */
		if (Gp_role == GP_ROLE_EXECUTE || IsBinaryUpgrade)
		{
			new_array_oid = GetPreassignedOidForType(relnamespace, relarrayname,
													 true);

			if (new_array_oid == InvalidOid && IsBinaryUpgrade)
				new_array_oid = GetNewOid(pg_type);
		}
		else
			new_array_oid = GetNewOid(pg_type);
		heap_close(pg_type, AccessShareLock);
	}

	/*
	 * Since defining a relation also defines a complex type, we add a new
	 * system type corresponding to the new relation.  The OID of the type can
	 * be preselected by the caller, but if reltypeid is InvalidOid, we'll
	 * generate a new OID for it.
	 *
	 * NOTE: we could get a unique-index failure here, in case someone else is
	 * creating the same type name in parallel but hadn't committed yet when
	 * we checked for a duplicate name above.
	 */
	new_type_oid = AddNewRelationType(relname,
									  relnamespace,
									  relid,
									  relkind,
									  ownerid,
									  reltypeid,
									  new_array_oid);

	/*
	 * Now make the array type if wanted.
	 */
	if (OidIsValid(new_array_oid))
	{
		if (!relarrayname)
			relarrayname = makeArrayTypeName(relname, relnamespace);

		TypeCreate(new_array_oid,		/* force the type's OID to this */
				   relarrayname,	/* Array type name */
				   relnamespace,	/* Same namespace as parent */
				   InvalidOid,	/* Not composite, no relationOid */
				   0,			/* relkind, also N/A here */
				   ownerid,		/* owner's ID */
				   -1,			/* Internal size (varlena) */
				   TYPTYPE_BASE,	/* Not composite - typelem is */
				   TYPCATEGORY_ARRAY,	/* type-category (array) */
				   false,		/* array types are never preferred */
				   DEFAULT_TYPDELIM,	/* default array delimiter */
				   F_ARRAY_IN,	/* array input proc */
				   F_ARRAY_OUT, /* array output proc */
				   F_ARRAY_RECV,	/* array recv (bin) proc */
				   F_ARRAY_SEND,	/* array send (bin) proc */
				   InvalidOid,	/* typmodin procedure - none */
				   InvalidOid,	/* typmodout procedure - none */
				   F_ARRAY_TYPANALYZE,	/* array analyze procedure */
				   new_type_oid,	/* array element type - the rowtype */
				   true,		/* yes, this is an array type */
				   InvalidOid,	/* this has no array type */
				   InvalidOid,	/* domain base type - irrelevant */
				   NULL,		/* default value - none */
				   NULL,		/* default binary representation */
				   false,		/* passed by reference */
				   'd',			/* alignment - must be the largest! */
				   'x',			/* fully TOASTable */
				   -1,			/* typmod */
				   0,			/* array dimensions for typBaseType */
				   false,		/* Type NOT NULL */
				   InvalidOid); /* rowtypes never have a collation */

		pfree(relarrayname);
	}

	/*
	 * now create an entry in pg_class for the relation.
	 *
	 * NOTE: we could get a unique-index failure here, in case someone else is
	 * creating the same relation name in parallel but hadn't committed yet
	 * when we checked for a duplicate name above.
	 */
	AddNewRelationTuple(pg_class_desc,
						new_rel_desc,
						relid,
						new_type_oid,
						reloftypeid,
						ownerid,
						relkind,
						relstorage,
						PointerGetDatum(relacl),
						reloptions,
						is_part_parent);

	/*
	 * if this is an append-only relation, add an entry in pg_appendonly.
	 */
	if(appendOnlyRel)
	{
		InsertAppendOnlyEntry(relid,
							  stdRdOptions->blocksize,
							  safefswritesize,
							  stdRdOptions->compresslevel,
							  stdRdOptions->checksum,
                              stdRdOptions->columnstore,
							  stdRdOptions->compresstype,
							  InvalidOid,
							  InvalidOid,
							  InvalidOid,
							  InvalidOid,
							  InvalidOid);
	}


	/*
	 * now add tuples to pg_attribute for the attributes in our new relation.
	 */
	AddNewAttributeTuples(relid, new_rel_desc->rd_att, relkind,
						  oidislocal, oidinhcount);

	/*
	 * Make a dependency link to force the relation to be deleted if its
	 * namespace is.  Also make a dependency link to its owner, as well as
	 * dependencies for any roles mentioned in the default ACL.
	 *
	 * For composite types, these dependencies are tracked for the pg_type
	 * entry, so we needn't record them here.  Likewise, TOAST tables don't
	 * need a namespace dependency (they live in a pinned namespace) nor an
	 * owner dependency (they depend indirectly through the parent table), nor
	 * should they have any ACL entries.  The same applies for extension
	 * dependencies.
	 *
	 * If it's a temp table, we do not make it an extension member; this
	 * prevents the unintuitive result that deletion of the temp table at
	 * session end would make the whole extension go away.
	 *
	 * Also, skip this in bootstrap mode, since we don't make dependencies
	 * while bootstrapping.
	 *
	 * GPDB: The section about TOAST is still relevant for AO aux tables.
	 */
	if (relkind != RELKIND_COMPOSITE_TYPE &&
		relkind != RELKIND_TOASTVALUE &&
		!IsAppendonlyMetadataRelkind(relkind) &&
		!IsBootstrapProcessingMode())
	{
		ObjectAddress myself,
					referenced;

		myself.classId = RelationRelationId;
		myself.objectId = relid;
		myself.objectSubId = 0;

		referenced.classId = NamespaceRelationId;
		referenced.objectId = relnamespace;
		referenced.objectSubId = 0;
		recordDependencyOn(&myself, &referenced, DEPENDENCY_NORMAL);

		recordDependencyOnOwner(RelationRelationId, relid, ownerid);

		recordDependencyOnNewAcl(RelationRelationId, relid, 0, ownerid, relacl);

		if (relpersistence != RELPERSISTENCE_TEMP)
			recordDependencyOnCurrentExtension(&myself, false);

		if (reloftypeid)
		{
			referenced.classId = TypeRelationId;
			referenced.objectId = reloftypeid;
			referenced.objectSubId = 0;
			recordDependencyOn(&myself, &referenced, DEPENDENCY_NORMAL);
		}
	}

	/* Post creation hook for new relation */
	InvokeObjectPostCreateHookArg(RelationRelationId, relid, 0, is_internal);

	/*
	 * Store any supplied constraints and defaults.
	 *
	 * NB: this may do a CommandCounterIncrement and rebuild the relcache
	 * entry, so the relation must be valid and self-consistent at this point.
	 * In particular, there are not yet constraints and defaults anywhere.
	 */
	StoreConstraints(new_rel_desc, cooked_constraints, is_internal);

	/*
	 * If there's a special on-commit action, remember it
	 */
	if (oncommit != ONCOMMIT_NOOP)
		register_on_commit_action(relid, oncommit);

	/*
	 * CDB: If caller gave us a distribution policy, store the distribution
	 * key column list in the gp_distribution_policy catalog and attach a
	 * copy to the relcache entry.
	 */
	if (policy &&
			(Gp_role == GP_ROLE_DISPATCH ||
			 Gp_role == GP_ROLE_EXECUTE ||
			 IsBinaryUpgrade))
	{
		MemoryContext oldcontext;

		Assert(relkind == RELKIND_RELATION || relkind == RELKIND_MATVIEW);

		oldcontext = MemoryContextSwitchTo(GetMemoryChunkContext(new_rel_desc));
		new_rel_desc->rd_cdbpolicy = GpPolicyCopy(policy);
		MemoryContextSwitchTo(oldcontext);
		GpPolicyStore(relid, policy);
	}

	if (Gp_role == GP_ROLE_DISPATCH) /* MPP-11313: */
	{
		bool doIt = true;
		char *subtyp = "TABLE";

		switch (relkind)
		{
			case RELKIND_RELATION:
				break;
			case RELKIND_INDEX:
				subtyp = "INDEX";
				break;
			case RELKIND_SEQUENCE:
				subtyp = "SEQUENCE";
				break;
			case RELKIND_VIEW:
				subtyp = "VIEW";
				break;
			case RELKIND_MATVIEW:
				subtyp = "MATVIEW";
				break;
			default:
				doIt = false;
		}

		/* MPP-7576: don't track internal namespace tables */
		switch (relnamespace) 
		{
			case PG_CATALOG_NAMESPACE:
				/* MPP-7773: don't track objects in system namespace
				 * if modifying system tables (eg during upgrade)  
				 */
				if (allowSystemTableMods)
					doIt = false;
				break;

			case PG_TOAST_NAMESPACE:
			case PG_BITMAPINDEX_NAMESPACE:
			case PG_AOSEGMENT_NAMESPACE:
				doIt = false;
				break;
			default:
				break;
		}

		/* MPP-7572: not valid if in any temporary namespace */
		if (doIt)
			doIt = (!(isAnyTempNamespace(relnamespace)));

		/* MPP-6929: metadata tracking */
		if (doIt)
			MetaTrackAddObject(RelationRelationId,
							   relid, GetUserId(), /* not ownerid */
							   "CREATE", subtyp
					);
	}

	/*
	 * If this is an unlogged relation, it needs an init fork so that it can
	 * be correctly reinitialized on restart.  Since we're going to do an
	 * immediate sync, we ony need to xlog this if archiving or streaming is
	 * enabled.  And the immediate sync is required, because otherwise there's
	 * no guarantee that this will hit the disk before the next checkpoint
	 * moves the redo pointer.
	 */
	if (relpersistence == RELPERSISTENCE_UNLOGGED)
	{
		Assert(relkind == RELKIND_RELATION || relkind == RELKIND_MATVIEW ||
			   relkind == RELKIND_TOASTVALUE || IsAppendonlyMetadataRelkind(relkind));
		heap_create_init_fork(new_rel_desc);
	}

	/*
	 * ok, the relation has been cataloged, so close our relations and return
	 * the OID of the newly created relation.
	 */
	heap_close(new_rel_desc, NoLock);	/* do not unlock till end of xact */
	heap_close(pg_class_desc, RowExclusiveLock);

	return relid;
}

/*
 * Set up an init fork for an unlogged table so that it can be correctly
 * reinitialized on restart.  An immediate sync is required even if the
 * page has been logged, because the write did not go through
 * shared_buffers and therefore a concurrent checkpoint may have moved
 * the redo pointer past our xlog record.  Recovery may as well remove it
 * while replaying, for example, XLOG_DBASE_CREATE or XLOG_TBLSPC_CREATE
 * record. Therefore, logging is necessary even if wal_level=minimal.
 */
void
heap_create_init_fork(Relation rel)
{
	RelationOpenSmgr(rel);
	smgrcreate(rel->rd_smgr, INIT_FORKNUM, false);
	log_smgrcreate(&rel->rd_smgr->smgr_rnode.node, INIT_FORKNUM);
	smgrimmedsync(rel->rd_smgr, INIT_FORKNUM);
}

/*
 *		RelationRemoveInheritance
 *
 * Formerly, this routine checked for child relations and aborted the
 * deletion if any were found.  Now we rely on the dependency mechanism
 * to check for or delete child relations.  By the time we get here,
 * there are no children and we need only remove any pg_inherits rows
 * linking this relation to its parent(s).
 */
static void
RelationRemoveInheritance(Oid relid)
{
	Relation	catalogRelation;
	SysScanDesc scan;
	ScanKeyData key;
	HeapTuple	tuple;

	catalogRelation = heap_open(InheritsRelationId, RowExclusiveLock);

	ScanKeyInit(&key,
				Anum_pg_inherits_inhrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	scan = systable_beginscan(catalogRelation, InheritsRelidSeqnoIndexId, true,
							  NULL, 1, &key);

	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
		CatalogTupleDelete(catalogRelation, &tuple->t_self);

	systable_endscan(scan);
	heap_close(catalogRelation, RowExclusiveLock);
}

static void
RemovePartitioning(Oid relid)
{
	Relation rel;
	SysScanDesc scan;
	ScanKeyData key;
	HeapTuple tuple;
	Relation pgrule;

	if (Gp_role == GP_ROLE_EXECUTE)
		return;

	RemovePartitionEncodingByRelid(relid);

	/* loop through all matches in pg_partition */
	rel = heap_open(PartitionRelationId, RowExclusiveLock);
	pgrule = heap_open(PartitionRuleRelationId,
					   RowExclusiveLock);

	ScanKeyInit(&key,
				Anum_pg_partition_parrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	scan = systable_beginscan(rel, PartitionParrelidIndexId, true,
							  NULL, 1, &key);
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		Oid			paroid = HeapTupleGetOid(tuple);
		SysScanDesc rule_scan;
		ScanKeyData rule_key;
		HeapTuple	rule_tuple;

		/* remove all rows for pg_partition_rule */
		ScanKeyInit(&rule_key,
					Anum_pg_partition_rule_paroid,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(paroid));
		rule_scan = systable_beginscan(pgrule, PartitionRuleParoidParparentruleParruleordIndexId, true,
									   NULL, 1, &rule_key);
		while (HeapTupleIsValid(rule_tuple = systable_getnext(rule_scan)))
			CatalogTupleDelete(pgrule, &rule_tuple->t_self);
		systable_endscan(rule_scan);

		/* remove ourself */
		CatalogTupleDelete(rel, &tuple->t_self);
	}
	systable_endscan(scan);
	heap_close(rel, NoLock);

	/* we might be a leaf partition: delete any records */

	ScanKeyInit(&key,
				Anum_pg_partition_rule_parchildrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	scan = systable_beginscan(pgrule, PartitionRuleParchildrelidIndexId, true,
							  NULL, 1, &key);
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
		CatalogTupleDelete(pgrule, &tuple->t_self);
	systable_endscan(scan);
	heap_close(pgrule, NoLock);

	CommandCounterIncrement();
}

/*
 *		DeleteRelationTuple
 *
 * Remove pg_class row for the given relid.
 *
 * Note: this is shared by relation deletion and index deletion.  It's
 * not intended for use anyplace else.
 */
void
DeleteRelationTuple(Oid relid)
{
	Relation	pg_class_desc;
	HeapTuple	tup;

	/* Grab an appropriate lock on the pg_class relation */
	pg_class_desc = heap_open(RelationRelationId, RowExclusiveLock);

	tup = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));
	if (!HeapTupleIsValid(tup))
		elog(ERROR, "cache lookup failed for relation %u", relid);

	/* delete the relation tuple from pg_class, and finish up */
	CatalogTupleDelete(pg_class_desc, &tup->t_self);

	ReleaseSysCache(tup);

	heap_close(pg_class_desc, RowExclusiveLock);
}

/*
 *		DeleteAttributeTuples
 *
 * Remove pg_attribute rows for the given relid.
 *
 * Note: this is shared by relation deletion and index deletion.  It's
 * not intended for use anyplace else.
 */
void
DeleteAttributeTuples(Oid relid)
{
	Relation	attrel;
	SysScanDesc scan;
	ScanKeyData key[1];
	HeapTuple	atttup;

	/* Grab an appropriate lock on the pg_attribute relation */
	attrel = heap_open(AttributeRelationId, RowExclusiveLock);

	/* Use the index to scan only attributes of the target relation */
	ScanKeyInit(&key[0],
				Anum_pg_attribute_attrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	scan = systable_beginscan(attrel, AttributeRelidNumIndexId, true,
							  NULL, 1, key);

	/* Delete all the matching tuples */
	while ((atttup = systable_getnext(scan)) != NULL)
		CatalogTupleDelete(attrel, &atttup->t_self);

	/* Clean up after the scan */
	systable_endscan(scan);
	heap_close(attrel, RowExclusiveLock);
}

/*
 *		DeleteSystemAttributeTuples
 *
 * Remove pg_attribute rows for system columns of the given relid.
 *
 * Note: this is only used when converting a table to a view.  Views don't
 * have system columns, so we should remove them from pg_attribute.
 */
void
DeleteSystemAttributeTuples(Oid relid)
{
	Relation	attrel;
	SysScanDesc scan;
	ScanKeyData key[2];
	HeapTuple	atttup;

	/* Grab an appropriate lock on the pg_attribute relation */
	attrel = heap_open(AttributeRelationId, RowExclusiveLock);

	/* Use the index to scan only system attributes of the target relation */
	ScanKeyInit(&key[0],
				Anum_pg_attribute_attrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));
	ScanKeyInit(&key[1],
				Anum_pg_attribute_attnum,
				BTLessEqualStrategyNumber, F_INT2LE,
				Int16GetDatum(0));

	scan = systable_beginscan(attrel, AttributeRelidNumIndexId, true,
							  NULL, 2, key);

	/* Delete all the matching tuples */
	while ((atttup = systable_getnext(scan)) != NULL)
		CatalogTupleDelete(attrel, &atttup->t_self);

	/* Clean up after the scan */
	systable_endscan(scan);
	heap_close(attrel, RowExclusiveLock);
}

/*
 *		RemoveAttributeById
 *
 * This is the guts of ALTER TABLE DROP COLUMN: actually mark the attribute
 * deleted in pg_attribute.  We also remove pg_statistic entries for it.
 * (Everything else needed, such as getting rid of any pg_attrdef entry,
 * is handled by dependency.c.)
 */
void
RemoveAttributeById(Oid relid, AttrNumber attnum)
{
	Relation	rel;
	Relation	attr_rel;
	HeapTuple	tuple;
	Form_pg_attribute attStruct;
	char		newattname[NAMEDATALEN];

	/*
	 * Grab an exclusive lock on the target table, which we will NOT release
	 * until end of transaction.  (In the simple case where we are directly
	 * dropping this column, AlterTableDropColumn already did this ... but
	 * when cascading from a drop of some other object, we may not have any
	 * lock.)
	 */
	rel = relation_open(relid, AccessExclusiveLock);

	attr_rel = heap_open(AttributeRelationId, RowExclusiveLock);

	tuple = SearchSysCacheCopy2(ATTNUM,
								ObjectIdGetDatum(relid),
								Int16GetDatum(attnum));
	if (!HeapTupleIsValid(tuple))		/* shouldn't happen */
		elog(ERROR, "cache lookup failed for attribute %d of relation %u",
			 attnum, relid);
	attStruct = (Form_pg_attribute) GETSTRUCT(tuple);

	if (attnum < 0)
	{
		/* System attribute (probably OID) ... just delete the row */

		CatalogTupleDelete(attr_rel, &tuple->t_self);
	}
	else
	{
		/* Dropping user attributes is lots harder */

		/* Mark the attribute as dropped */
		attStruct->attisdropped = true;

		/*
		 * Set the type OID to invalid.  A dropped attribute's type link
		 * cannot be relied on (once the attribute is dropped, the type might
		 * be too). Fortunately we do not need the type row --- the only
		 * really essential information is the type's typlen and typalign,
		 * which are preserved in the attribute's attlen and attalign.  We set
		 * atttypid to zero here as a means of catching code that incorrectly
		 * expects it to be valid.
		 */
		attStruct->atttypid = InvalidOid;

		/* Remove any NOT NULL constraint the column may have */
		attStruct->attnotnull = false;

		/* We don't want to keep stats for it anymore */
		attStruct->attstattarget = 0;

		/* Update distribution policy for dropped distribution column */
		if (GpPolicyIsHashPartitioned(rel->rd_cdbpolicy))
		{
			int            ia = 0;

			for (ia = 0; ia < rel->rd_cdbpolicy->nattrs; ia++)
			{
				if (attnum == rel->rd_cdbpolicy->attrs[ia])
				{
					MemoryContext oldcontext;
					GpPolicy *policy;

					/* force a random distribution */
					rel->rd_cdbpolicy->nattrs = 0;

					oldcontext = MemoryContextSwitchTo(GetMemoryChunkContext(rel));
					policy = GpPolicyCopy(rel->rd_cdbpolicy);
					MemoryContextSwitchTo(oldcontext);

					/*
					 * replace policy first in catalog and then assign to
					 * rd_cdbpolicy to make sure we have intended policy in relcache
					 * even with relcache invalidation. Otherwise rd_cdbpolicy can
					 * become invalid soon after assignment.
					 */
					GpPolicyReplace(RelationGetRelid(rel), policy);
					rel->rd_cdbpolicy = policy;
					if (Gp_role != GP_ROLE_EXECUTE)
						ereport(NOTICE,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
									errmsg("dropping a column that is part of the distribution policy forces a NULL distribution policy")));
				}
			}
		}

		/*
		 * Change the column name to something that isn't likely to conflict
		 */
		snprintf(newattname, sizeof(newattname),
				 "........pg.dropped.%d........", attnum);
		namestrcpy(&(attStruct->attname), newattname);

		CatalogTupleUpdate(attr_rel, &tuple->t_self, tuple);
	}

	/*
	 * Because updating the pg_attribute row will trigger a relcache flush for
	 * the target relation, we need not do anything else to notify other
	 * backends of the change.
	 */

	heap_close(attr_rel, RowExclusiveLock);

	if (attnum > 0)
		RemoveStatistics(relid, attnum);

	relation_close(rel, NoLock);
}

/*
 *		RemoveAttrDefault
 *
 * If the specified relation/attribute has a default, remove it.
 * (If no default, raise error if complain is true, else return quietly.)
 */
void
RemoveAttrDefault(Oid relid, AttrNumber attnum,
				  DropBehavior behavior, bool complain, bool internal)
{
	Relation	attrdef_rel;
	ScanKeyData scankeys[2];
	SysScanDesc scan;
	HeapTuple	tuple;
	bool		found = false;

	attrdef_rel = heap_open(AttrDefaultRelationId, RowExclusiveLock);

	ScanKeyInit(&scankeys[0],
				Anum_pg_attrdef_adrelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));
	ScanKeyInit(&scankeys[1],
				Anum_pg_attrdef_adnum,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(attnum));

	scan = systable_beginscan(attrdef_rel, AttrDefaultIndexId, true,
							  NULL, 2, scankeys);

	/* There should be at most one matching tuple, but we loop anyway */
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		ObjectAddress object;

		object.classId = AttrDefaultRelationId;
		object.objectId = HeapTupleGetOid(tuple);
		object.objectSubId = 0;

		performDeletion(&object, behavior,
						internal ? PERFORM_DELETION_INTERNAL : 0);

		found = true;
	}

	systable_endscan(scan);
	heap_close(attrdef_rel, RowExclusiveLock);

	if (complain && !found)
		elog(ERROR, "could not find attrdef tuple for relation %u attnum %d",
			 relid, attnum);
}

/*
 *		RemoveAttrDefaultById
 *
 * Remove a pg_attrdef entry specified by OID.  This is the guts of
 * attribute-default removal.  Note it should be called via performDeletion,
 * not directly.
 */
void
RemoveAttrDefaultById(Oid attrdefId)
{
	Relation	attrdef_rel;
	Relation	attr_rel;
	Relation	myrel;
	ScanKeyData scankeys[1];
	SysScanDesc scan;
	HeapTuple	tuple;
	Oid			myrelid;
	AttrNumber	myattnum;

	/* Grab an appropriate lock on the pg_attrdef relation */
	attrdef_rel = heap_open(AttrDefaultRelationId, RowExclusiveLock);

	/* Find the pg_attrdef tuple */
	ScanKeyInit(&scankeys[0],
				ObjectIdAttributeNumber,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(attrdefId));

	scan = systable_beginscan(attrdef_rel, AttrDefaultOidIndexId, true,
							  NULL, 1, scankeys);

	tuple = systable_getnext(scan);
	if (!HeapTupleIsValid(tuple))
		elog(ERROR, "could not find tuple for attrdef %u", attrdefId);

	myrelid = ((Form_pg_attrdef) GETSTRUCT(tuple))->adrelid;
	myattnum = ((Form_pg_attrdef) GETSTRUCT(tuple))->adnum;

	/* Get an exclusive lock on the relation owning the attribute */
	myrel = relation_open(myrelid, AccessExclusiveLock);

	/* Now we can delete the pg_attrdef row */
	CatalogTupleDelete(attrdef_rel, &tuple->t_self);

	systable_endscan(scan);
	heap_close(attrdef_rel, RowExclusiveLock);

	/* Fix the pg_attribute row */
	attr_rel = heap_open(AttributeRelationId, RowExclusiveLock);

	tuple = SearchSysCacheCopy2(ATTNUM,
								ObjectIdGetDatum(myrelid),
								Int16GetDatum(myattnum));
	if (!HeapTupleIsValid(tuple))		/* shouldn't happen */
		elog(ERROR, "cache lookup failed for attribute %d of relation %u",
			 myattnum, myrelid);

	((Form_pg_attribute) GETSTRUCT(tuple))->atthasdef = false;

	CatalogTupleUpdate(attr_rel, &tuple->t_self, tuple);

	/*
	 * Our update of the pg_attribute row will force a relcache rebuild, so
	 * there's nothing else to do here.
	 */
	heap_close(attr_rel, RowExclusiveLock);

	/* Keep lock on attribute's rel until end of xact */
	relation_close(myrel, NoLock);
}

/*
 * heap_drop_with_catalog	- removes specified relation from catalogs
 *
 * Note that this routine is not responsible for dropping objects that are
 * linked to the pg_class entry via dependencies (for example, indexes and
 * constraints).  Those are deleted by the dependency-tracing logic in
 * dependency.c before control gets here.  In general, therefore, this routine
 * should never be called directly; go through performDeletion() instead.
 */
void
heap_drop_with_catalog(Oid relid)
{
	Relation	rel;
	bool		is_appendonly_rel;
	bool		is_external_rel;
	char		relkind;

	/*
	 * Open and lock the relation.
	 */
	rel = relation_open(relid, AccessExclusiveLock);

	relkind = rel->rd_rel->relkind;

	is_appendonly_rel = RelationIsAppendOptimized(rel);
	is_external_rel = RelationIsExternal(rel);

	/*
	 * There can no longer be anyone *else* touching the relation, but we
	 * might still have open queries or cursors, or pending trigger events, in
	 * our own session.
	 */
	CheckTableNotInUse(rel, "DROP TABLE");

	/*
	 * This effectively deletes all rows in the table, and may be done in a
	 * serializable transaction.  In that case we must record a rw-conflict in
	 * to this transaction from each transaction holding a predicate lock on
	 * the table.
	 */
	CheckTableForSerializableConflictIn(rel);

	/*
	 * Delete pg_foreign_table tuple first.
	 */
	if (rel->rd_rel->relkind == RELKIND_FOREIGN_TABLE)
	{
		Relation	rel;
		HeapTuple	tuple;

		rel = heap_open(ForeignTableRelationId, RowExclusiveLock);

		tuple = SearchSysCache1(FOREIGNTABLEREL, ObjectIdGetDatum(relid));
		if (!HeapTupleIsValid(tuple))
			elog(ERROR, "cache lookup failed for foreign table %u", relid);

		CatalogTupleDelete(rel, &tuple->t_self);

		ReleaseSysCache(tuple);
		heap_close(rel, RowExclusiveLock);
	}

	/*
	 * Schedule unlinking of the relation's physical files at commit.
	 */
	if (relkind != RELKIND_VIEW &&
		relkind != RELKIND_COMPOSITE_TYPE &&
		relkind != RELKIND_FOREIGN_TABLE &&
		!RelationIsExternal(rel))
	{
		RelationDropStorage(rel);
	}

	/*
	 * Close relcache entry, but *keep* AccessExclusiveLock on the relation
	 * until transaction commit.  This ensures no one else will try to do
	 * something with the doomed relation.
	 */
	relation_close(rel, NoLock);

	/*
	 * Forget any ON COMMIT action for the rel
	 */
	remove_on_commit_action(relid);

	/*
	 * Flush the relation from the relcache.  We want to do this before
	 * starting to remove catalog entries, just to be certain that no relcache
	 * entry rebuild will happen partway through.  (That should not really
	 * matter, since we don't do CommandCounterIncrement here, but let's be
	 * safe.)
	 */
	RelationForgetRelation(relid);

	/*
	 * remove inheritance information
	 */
	RelationRemoveInheritance(relid);

	/*
	 * remove partitioning configuration
	 */
	RemovePartitioning(relid);

	/*
	 * delete statistics
	 */
	RemoveStatistics(relid, 0);

	/*
	 * delete attribute tuples
	 */
	DeleteAttributeTuples(relid);

	/*
	 * delete relation tuple
	 */
	DeleteRelationTuple(relid);

	/*
	 * delete error log file
	 */
	ErrorLogDelete(MyDatabaseId, relid);

	/*
	 * append-only table? delete the corresponding pg_appendonly tuple
	 */
	if(is_appendonly_rel)
		RemoveAppendonlyEntry(relid);

	/*
	 * External table? If so, delete the pg_exttable tuple.
	 */
	if (is_external_rel)
		RemoveExtTableEntry(relid);

	/*
	 * Remove distribution policy, if any.
 	 */
	if (relkind == RELKIND_RELATION || relkind == RELKIND_MATVIEW)
		GpPolicyRemove(relid);

	/*
	 * Attribute encoding
	 */
	if (relkind == RELKIND_RELATION || relkind == RELKIND_MATVIEW)
		RemoveAttributeEncodingsByRelid(relid);

	/* MPP-6929: metadata tracking */
	MetaTrackDropObject(RelationRelationId,
						relid);

}


/*
 * Store a default expression for column attnum of relation rel.
 */
void
StoreAttrDefault(Relation rel, AttrNumber attnum,
				 Node *expr, bool is_internal)
{
	char	   *adbin;
	char	   *adsrc;
	Relation	adrel;
	HeapTuple	tuple;
	Datum		values[4];
	static bool nulls[4] = {false, false, false, false};
	Relation	attrrel;
	HeapTuple	atttup;
	Form_pg_attribute attStruct;
	Oid			attrdefOid;
	ObjectAddress colobject,
				defobject;

	/*
	 * Flatten expression to string form for storage.
	 */
	adbin = nodeToString(expr);

	/*
	 * Also deparse it to form the mostly-obsolete adsrc field.
	 */
	adsrc = deparse_expression(expr,
							deparse_context_for(RelationGetRelationName(rel),
												RelationGetRelid(rel)),
							   false, false);

	/*
	 * Make the pg_attrdef entry.
	 */
	values[Anum_pg_attrdef_adrelid - 1] = RelationGetRelid(rel);
	values[Anum_pg_attrdef_adnum - 1] = attnum;
	values[Anum_pg_attrdef_adbin - 1] = CStringGetTextDatum(adbin);
	values[Anum_pg_attrdef_adsrc - 1] = CStringGetTextDatum(adsrc);

	adrel = heap_open(AttrDefaultRelationId, RowExclusiveLock);

	tuple = heap_form_tuple(adrel->rd_att, values, nulls);
	attrdefOid = CatalogTupleInsert(adrel, tuple);

	defobject.classId = AttrDefaultRelationId;
	defobject.objectId = attrdefOid;
	defobject.objectSubId = 0;

	heap_close(adrel, RowExclusiveLock);

	/* now can free some of the stuff allocated above */
	pfree(DatumGetPointer(values[Anum_pg_attrdef_adbin - 1]));
	pfree(DatumGetPointer(values[Anum_pg_attrdef_adsrc - 1]));
	heap_freetuple(tuple);
	pfree(adbin);
	pfree(adsrc);

	/*
	 * Update the pg_attribute entry for the column to show that a default
	 * exists.
	 */
	attrrel = heap_open(AttributeRelationId, RowExclusiveLock);
	atttup = SearchSysCacheCopy2(ATTNUM,
								 ObjectIdGetDatum(RelationGetRelid(rel)),
								 Int16GetDatum(attnum));
	if (!HeapTupleIsValid(atttup))
		elog(ERROR, "cache lookup failed for attribute %d of relation %u",
			 attnum, RelationGetRelid(rel));
	attStruct = (Form_pg_attribute) GETSTRUCT(atttup);
	if (!attStruct->atthasdef)
	{
		attStruct->atthasdef = true;
		CatalogTupleUpdate(attrrel, &atttup->t_self, atttup);
	}
	heap_close(attrrel, RowExclusiveLock);
	heap_freetuple(atttup);

	/*
	 * Make a dependency so that the pg_attrdef entry goes away if the column
	 * (or whole table) is deleted.
	 */
	colobject.classId = RelationRelationId;
	colobject.objectId = RelationGetRelid(rel);
	colobject.objectSubId = attnum;

	recordDependencyOn(&defobject, &colobject, DEPENDENCY_AUTO);

	/*
	 * Record dependencies on objects used in the expression, too.
	 */
	recordDependencyOnExpr(&defobject, expr, NIL, DEPENDENCY_NORMAL);

	/*
	 * Post creation hook for attribute defaults.
	 *
	 * XXX. ALTER TABLE ALTER COLUMN SET/DROP DEFAULT is implemented with a
	 * couple of deletion/creation of the attribute's default entry, so the
	 * callee should check existence of an older version of this entry if it
	 * needs to distinguish.
	 */
	InvokeObjectPostCreateHookArg(AttrDefaultRelationId,
								  RelationGetRelid(rel), attnum, is_internal);
}

/*
 * Store a check-constraint expression for the given relation.
 *
 * Caller is responsible for updating the count of constraints
 * in the pg_class entry for the relation.
 */
static void
StoreRelCheck(Relation rel, char *ccname, Node *expr,
			  bool is_validated, bool is_local, int inhcount,
			  bool is_no_inherit, bool is_internal)
{
	char	   *ccbin;
	char	   *ccsrc;
	List	   *varList;
	int			keycount;
	int16	   *attNos;

	/*
	 * Flatten expression to string form for storage.
	 */
	ccbin = nodeToString(expr);

	/*
	 * Also deparse it to form the mostly-obsolete consrc field.
	 */
	ccsrc = deparse_expression(expr,
							deparse_context_for(RelationGetRelationName(rel),
												RelationGetRelid(rel)),
							   false, false);

	/*
	 * Find columns of rel that are used in expr
	 *
	 * NB: pull_var_clause is okay here only because we don't allow subselects
	 * in check constraints; it would fail to examine the contents of
	 * subselects.
	 */
	varList = pull_var_clause(expr,
							  PVC_REJECT_AGGREGATES,
							  PVC_REJECT_PLACEHOLDERS);
	keycount = list_length(varList);

	if (keycount > 0)
	{
		ListCell   *vl;
		int			i = 0;

		attNos = (int16 *) palloc(keycount * sizeof(int16));
		foreach(vl, varList)
		{
			Var		   *var = (Var *) lfirst(vl);
			int			j;

			for (j = 0; j < i; j++)
				if (attNos[j] == var->varattno)
					break;
			if (j == i)
				attNos[i++] = var->varattno;
		}
		keycount = i;
	}
	else
		attNos = NULL;

	/*
	 * Create the Check Constraint
	 */
	CreateConstraintEntry(ccname,		/* Constraint Name */
						  RelationGetNamespace(rel),	/* namespace */
						  CONSTRAINT_CHECK,		/* Constraint Type */
						  false,	/* Is Deferrable */
						  false,	/* Is Deferred */
						  is_validated,
						  RelationGetRelid(rel),		/* relation */
						  attNos,		/* attrs in the constraint */
						  keycount,		/* # attrs in the constraint */
						  InvalidOid,	/* not a domain constraint */
						  InvalidOid,	/* no associated index */
						  InvalidOid,	/* Foreign key fields */
						  NULL,
						  NULL,
						  NULL,
						  NULL,
						  0,
						  ' ',
						  ' ',
						  ' ',
						  NULL, /* not an exclusion constraint */
						  expr, /* Tree form of check constraint */
						  ccbin,	/* Binary form of check constraint */
						  ccsrc,	/* Source form of check constraint */
						  is_local,		/* conislocal */
						  inhcount,		/* coninhcount */
						  is_no_inherit,		/* connoinherit */
						  is_internal); /* internally constructed? */

	pfree(ccbin);
	pfree(ccsrc);
}

/*
 * Store defaults and constraints (passed as a list of CookedConstraint).
 *
 * NOTE: only pre-cooked expressions will be passed this way, which is to
 * say expressions inherited from an existing relation.  Newly parsed
 * expressions can be added later, by direct calls to StoreAttrDefault
 * and StoreRelCheck (see AddRelationNewConstraints()).
 */
static void
StoreConstraints(Relation rel, List *cooked_constraints, bool is_internal)
{
	int			numchecks = 0;
	ListCell   *lc;

	if (!cooked_constraints)
		return;					/* nothing to do */

	/*
	 * Deparsing of constraint expressions will fail unless the just-created
	 * pg_attribute tuples for this relation are made visible.  So, bump the
	 * command counter.  CAUTION: this will cause a relcache entry rebuild.
	 */
	CommandCounterIncrement();

	foreach(lc, cooked_constraints)
	{
		CookedConstraint *con = (CookedConstraint *) lfirst(lc);

		switch (con->contype)
		{
			case CONSTR_DEFAULT:
				StoreAttrDefault(rel, con->attnum, con->expr, is_internal);
				break;
			case CONSTR_CHECK:
				StoreRelCheck(rel, con->name, con->expr, !con->skip_validation,
							  con->is_local, con->inhcount,
							  con->is_no_inherit, is_internal);
				numchecks++;
				break;
			default:
				elog(ERROR, "unrecognized constraint type: %d",
					 (int) con->contype);
		}
	}

	if (numchecks > 0)
		SetRelationNumChecks(rel, numchecks);
}

/*
 * AddRelationNewConstraints
 *
 * Add new column default expressions and/or constraint check expressions
 * to an existing relation.  This is defined to do both for efficiency in
 * DefineRelation, but of course you can do just one or the other by passing
 * empty lists.
 *
 * rel: relation to be modified
 * newColDefaults: list of RawColumnDefault structures
 * newConstraints: list of Constraint nodes
 * allow_merge: TRUE if check constraints may be merged with existing ones
 * is_local: TRUE if definition is local, FALSE if it's inherited
 * is_internal: TRUE if result of some internal process, not a user request
 *
 * All entries in newColDefaults will be processed.  Entries in newConstraints
 * will be processed only if they are CONSTR_CHECK type.
 *
 * Returns a list of CookedConstraint nodes that shows the cooked form of
 * the default and constraint expressions added to the relation.
 *
 * NB: caller should have opened rel with AccessExclusiveLock, and should
 * hold that lock till end of transaction.  Also, we assume the caller has
 * done a CommandCounterIncrement if necessary to make the relation's catalog
 * tuples visible.
 */
List *
AddRelationNewConstraints(Relation rel,
						  List *newColDefaults,
						  List *newConstraints,
						  bool allow_merge,
						  bool is_local,
						  bool is_internal)
{
	List	   *cookedConstraints = NIL;
	TupleDesc	tupleDesc;
	TupleConstr *oldconstr;
	int			numoldchecks;
	ParseState *pstate;
	RangeTblEntry *rte;
	int			numchecks;
	List	   *checknames;
	ListCell   *cell;
	Node	   *expr;
	CookedConstraint *cooked;

	/*
	 * Get info about existing constraints.
	 */
	tupleDesc = RelationGetDescr(rel);
	oldconstr = tupleDesc->constr;
	if (oldconstr)
		numoldchecks = oldconstr->num_check;
	else
		numoldchecks = 0;

	/*
	 * Create a dummy ParseState and insert the target relation as its sole
	 * rangetable entry.  We need a ParseState for transformExpr.
	 */
	pstate = make_parsestate(NULL);
	rte = addRangeTableEntryForRelation(pstate,
										rel,
										NULL,
										false,
										true);
	addRTEtoQuery(pstate, rte, true, true, true);

	/*
	 * Process column default expressions.
	 */
	foreach(cell, newColDefaults)
	{
		RawColumnDefault *colDef = (RawColumnDefault *) lfirst(cell);
		Form_pg_attribute atp = rel->rd_att->attrs[colDef->attnum - 1];

		expr = cookDefault(pstate, colDef->raw_default,
						   atp->atttypid, atp->atttypmod,
						   NameStr(atp->attname));

		/*
		 * If the expression is just a NULL constant, we do not bother to make
		 * an explicit pg_attrdef entry, since the default behavior is
		 * equivalent.
		 *
		 * Note a nonobvious property of this test: if the column is of a
		 * domain type, what we'll get is not a bare null Const but a
		 * CoerceToDomain expr, so we will not discard the default.  This is
		 * critical because the column default needs to be retained to
		 * override any default that the domain might have.
		 */
		if (expr == NULL ||
			(IsA(expr, Const) &&((Const *) expr)->constisnull))
			continue;

		StoreAttrDefault(rel, colDef->attnum, expr, is_internal);

		cooked = (CookedConstraint *) palloc(sizeof(CookedConstraint));
		cooked->contype = CONSTR_DEFAULT;
		cooked->name = NULL;
		cooked->attnum = colDef->attnum;
		cooked->expr = expr;
		cooked->skip_validation = false;
		cooked->is_local = is_local;
		cooked->inhcount = is_local ? 0 : 1;
		cooked->is_no_inherit = false;
		cookedConstraints = lappend(cookedConstraints, cooked);
	}

	/*
	 * Process constraint expressions.
	 */
	numchecks = numoldchecks;
	checknames = NIL;
	foreach(cell, newConstraints)
	{
		Constraint *cdef = (Constraint *) lfirst(cell);
		char	   *ccname;

		if (cdef->contype != CONSTR_CHECK)
			continue;

		if (cdef->raw_expr != NULL)
		{
			Assert(cdef->cooked_expr == NULL);

			/*
			 * Transform raw parsetree to executable expression, and verify
			 * it's valid as a CHECK constraint.
			 */
			expr = cookConstraint(pstate, cdef->raw_expr,
								  RelationGetRelationName(rel));
		}
		else
		{
			Assert(cdef->cooked_expr != NULL);

			/*
			 * Here, we assume the parser will only pass us valid CHECK
			 * expressions, so we do no particular checking.
			 */
			expr = stringToNode(cdef->cooked_expr);
		}

		/*
		 * Check name uniqueness, or generate a name if none was given.
		 */
		if (cdef->conname != NULL)
		{
			ListCell   *cell2;

			ccname = cdef->conname;
			/* Check against other new constraints */
			/* Needed because we don't do CommandCounterIncrement in loop */
			foreach(cell2, checknames)
			{
				if (strcmp((char *) lfirst(cell2), ccname) == 0)
					ereport(ERROR,
							(errcode(ERRCODE_DUPLICATE_OBJECT),
							 errmsg("check constraint \"%s\" already exists",
									ccname)));
			}

			/* save name for future checks */
			checknames = lappend(checknames, ccname);

			/*
			 * Check against pre-existing constraints.  If we are allowed to
			 * merge with an existing constraint, there's no more to do here.
			 * (We omit the duplicate constraint from the result, which is
			 * what ATAddCheckConstraint wants.)
			 */
			if (MergeWithExistingConstraint(rel, ccname, expr,
											allow_merge, is_local,
											cdef->initially_valid,
											cdef->is_no_inherit))
				continue;
		}
		else
		{
			/*
			 * When generating a name, we want to create "tab_col_check" for a
			 * column constraint and "tab_check" for a table constraint.  We
			 * no longer have any info about the syntactic positioning of the
			 * constraint phrase, so we approximate this by seeing whether the
			 * expression references more than one column.  (If the user
			 * played by the rules, the result is the same...)
			 *
			 * Note: pull_var_clause() doesn't descend into sublinks, but we
			 * eliminated those above; and anyway this only needs to be an
			 * approximate answer.
			 */
			List	   *vars;
			char	   *colname;

			vars = pull_var_clause(expr,
								   PVC_REJECT_AGGREGATES,
								   PVC_REJECT_PLACEHOLDERS);

			/* eliminate duplicates */
			vars = list_union(NIL, vars);

			if (list_length(vars) == 1)
				colname = get_attname(RelationGetRelid(rel),
									  ((Var *) linitial(vars))->varattno);
			else
				colname = NULL;

			ccname = ChooseConstraintName(RelationGetRelationName(rel),
										  colname,
										  "check",
										  RelationGetNamespace(rel),
										  checknames);

			/* save name for future checks */
			checknames = lappend(checknames, ccname);
		}

		/*
		 * OK, store it.
		 */
		StoreRelCheck(rel, ccname, expr, !cdef->skip_validation, is_local,
					  is_local ? 0 : 1, cdef->is_no_inherit, is_internal);

		numchecks++;

		cooked = (CookedConstraint *) palloc(sizeof(CookedConstraint));
		cooked->contype = CONSTR_CHECK;
		cooked->name = ccname;
		cooked->attnum = 0;
		cooked->expr = expr;
		cooked->skip_validation = cdef->skip_validation;
		cooked->is_local = is_local;
		cooked->inhcount = is_local ? 0 : 1;
		cooked->is_no_inherit = cdef->is_no_inherit;
		cookedConstraints = lappend(cookedConstraints, cooked);
	}

	/* Cleanup the parse state */
	free_parsestate(pstate);

	/*
	 * Update the count of constraints in the relation's pg_class tuple. We do
	 * this even if there was no change, in order to ensure that an SI update
	 * message is sent out for the pg_class tuple, which will force other
	 * backends to rebuild their relcache entries for the rel. (This is
	 * critical if we added defaults but not constraints.)
	 */
	SetRelationNumChecks(rel, numchecks);

	return cookedConstraints;
}

/*
 * Check for a pre-existing check constraint that conflicts with a proposed
 * new one, and either adjust its conislocal/coninhcount settings or throw
 * error as needed.
 *
 * Returns TRUE if merged (constraint is a duplicate), or FALSE if it's
 * got a so-far-unique name, or throws error if conflict.
 *
 * XXX See MergeConstraintsIntoExisting too if you change this code.
 */
static bool
MergeWithExistingConstraint(Relation rel, char *ccname, Node *expr,
							bool allow_merge, bool is_local,
							bool is_initially_valid,
							bool is_no_inherit)
{
	bool		found;
	Relation	conDesc;
	SysScanDesc conscan;
	ScanKeyData skey[2];
	HeapTuple	tup;

	/* Search for a pg_constraint entry with same name and relation */
	conDesc = heap_open(ConstraintRelationId, RowExclusiveLock);

	found = false;

	ScanKeyInit(&skey[0],
				Anum_pg_constraint_conname,
				BTEqualStrategyNumber, F_NAMEEQ,
				CStringGetDatum(ccname));

	ScanKeyInit(&skey[1],
				Anum_pg_constraint_connamespace,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(RelationGetNamespace(rel)));

	conscan = systable_beginscan(conDesc, ConstraintNameNspIndexId, true,
								 NULL, 2, skey);

	while (HeapTupleIsValid(tup = systable_getnext(conscan)))
	{
		Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tup);

		if (con->conrelid == RelationGetRelid(rel))
		{
			/* Found it.  Conflicts if not identical check constraint */
			if (con->contype == CONSTRAINT_CHECK)
			{
				Datum		val;
				bool		isnull;

				val = fastgetattr(tup,
								  Anum_pg_constraint_conbin,
								  conDesc->rd_att, &isnull);
				if (isnull)
					elog(ERROR, "null conbin for rel %s",
						 RelationGetRelationName(rel));
				if (equal(expr, stringToNode(TextDatumGetCString(val))))
					found = true;
			}

			/*
			 * If the existing constraint is purely inherited (no local
			 * definition) then interpret addition of a local constraint as a
			 * legal merge.  This allows ALTER ADD CONSTRAINT on parent and
			 * child tables to be given in either order with same end state.
			 */
			if (is_local && !con->conislocal)
				allow_merge = true;

			if (!found || !allow_merge)
				ereport(ERROR,
						(errcode(ERRCODE_DUPLICATE_OBJECT),
				errmsg("constraint \"%s\" for relation \"%s\" already exists",
					   ccname, RelationGetRelationName(rel))));

			/* If the child constraint is "no inherit" then cannot merge */
			if (con->connoinherit)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
						 errmsg("constraint \"%s\" conflicts with non-inherited constraint on relation \"%s\"",
								ccname, RelationGetRelationName(rel))));

			/*
			 * Must not change an existing inherited constraint to "no
			 * inherit" status.  That's because inherited constraints should
			 * be able to propagate to lower-level children.
			 */
			if (con->coninhcount > 0 && is_no_inherit)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
						 errmsg("constraint \"%s\" conflicts with inherited constraint on relation \"%s\"",
								ccname, RelationGetRelationName(rel))));

			/*
			 * If the child constraint is "not valid" then cannot merge with a
			 * valid parent constraint
			 */
			if (is_initially_valid && !con->convalidated)
				ereport(ERROR,
						(errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
						 errmsg("constraint \"%s\" conflicts with NOT VALID constraint on relation \"%s\"",
								ccname, RelationGetRelationName(rel))));

			/* OK to update the tuple */
			ereport(NOTICE,
			   (errmsg("merging constraint \"%s\" with inherited definition",
					   ccname)));

			tup = heap_copytuple(tup);
			con = (Form_pg_constraint) GETSTRUCT(tup);

			if (is_local)
				con->conislocal = true;
			else
				con->coninhcount++;
			if (is_no_inherit)
			{
				Assert(is_local);
				con->connoinherit = true;
			}
			CatalogTupleUpdate(conDesc, &tup->t_self, tup);
			break;
		}
	}

	systable_endscan(conscan);
	heap_close(conDesc, RowExclusiveLock);

	return found;
}

/*
 * Update the count of constraints in the relation's pg_class tuple.
 *
 * Caller had better hold exclusive lock on the relation.
 *
 * An important side effect is that a SI update message will be sent out for
 * the pg_class tuple, which will force other backends to rebuild their
 * relcache entries for the rel.  Also, this backend will rebuild its
 * own relcache entry at the next CommandCounterIncrement.
 */
void
SetRelationNumChecks(Relation rel, int numchecks)
{
	Relation	relrel;
	HeapTuple	reltup;
	Form_pg_class relStruct;

	relrel = heap_open(RelationRelationId, RowExclusiveLock);
	reltup = SearchSysCacheCopy1(RELOID,
								 ObjectIdGetDatum(RelationGetRelid(rel)));
	if (!HeapTupleIsValid(reltup))
		elog(ERROR, "cache lookup failed for relation %u",
			 RelationGetRelid(rel));
	relStruct = (Form_pg_class) GETSTRUCT(reltup);

	if (relStruct->relchecks != numchecks)
	{
		relStruct->relchecks = numchecks;

		CatalogTupleUpdate(relrel, &reltup->t_self, reltup);
	}
	else
	{
		/* Skip the disk update, but force relcache inval anyway */
		CacheInvalidateRelcache(rel);
	}

	heap_freetuple(reltup);
	heap_close(relrel, RowExclusiveLock);
}

/*
 * Take a raw default and convert it to a cooked format ready for
 * storage.
 *
 * Parse state should be set up to recognize any vars that might appear
 * in the expression.  (Even though we plan to reject vars, it's more
 * user-friendly to give the correct error message than "unknown var".)
 *
 * If atttypid is not InvalidOid, coerce the expression to the specified
 * type (and typmod atttypmod).   attname is only needed in this case:
 * it is used in the error message, if any.
 */
Node *
cookDefault(ParseState *pstate,
			Node *raw_default,
			Oid atttypid,
			int32 atttypmod,
			char *attname)
{
	Node	   *expr;

	Assert(raw_default != NULL);

	/*
	 * Transform raw parsetree to executable expression.
	 */
	expr = transformExpr(pstate, raw_default, EXPR_KIND_COLUMN_DEFAULT);

	/*
	 * Make sure default expr does not refer to any vars (we need this check
	 * since the pstate includes the target table).
	 */
	if (contain_var_clause(expr))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_COLUMN_REFERENCE),
			  errmsg("cannot use column references in default expression")));

	/*
	 * transformExpr() should have already rejected subqueries, aggregates,
	 * and window functions, based on the EXPR_KIND_ for a default expression.
	 *
	 * It can't return a set either.
	 */
	if (expression_returns_set(expr))
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("default expression must not return a set")));

	/*
	 * Coerce the expression to the correct type and typmod, if given. This
	 * should match the parser's processing of non-defaulted expressions ---
	 * see transformAssignedExpr().
	 */
	if (OidIsValid(atttypid))
	{
		Oid			type_id = exprType(expr);

		expr = coerce_to_target_type(pstate, expr, type_id,
									 atttypid, atttypmod,
									 COERCION_ASSIGNMENT,
									 COERCE_IMPLICIT_CAST,
									 -1);
		if (expr == NULL)
			ereport(ERROR,
					(errcode(ERRCODE_DATATYPE_MISMATCH),
					 errmsg("column \"%s\" is of type %s"
							" but default expression is of type %s",
							attname,
							format_type_be(atttypid),
							format_type_be(type_id)),
			   errhint("You will need to rewrite or cast the expression.")));
	}

	/*
	 * Finally, take care of collations in the finished expression.
	 */
	assign_expr_collations(pstate, expr);

	return expr;
}

/*
 * Take a raw CHECK constraint expression and convert it to a cooked format
 * ready for storage.
 *
 * Parse state must be set up to recognize any vars that might appear
 * in the expression.
 */
static Node *
cookConstraint(ParseState *pstate,
			   Node *raw_constraint,
			   char *relname)
{
	Node	   *expr;

	/*
	 * Transform raw parsetree to executable expression.
	 */
	expr = transformExpr(pstate, raw_constraint, EXPR_KIND_CHECK_CONSTRAINT);

	/*
	 * Make sure it yields a boolean result.
	 */
	expr = coerce_to_boolean(pstate, expr, "CHECK");

	/*
	 * Take care of collations.
	 */
	assign_expr_collations(pstate, expr);

	/*
	 * Make sure no outside relations are referred to (this is probably dead
	 * code now that add_missing_from is history).
	 */
	if (list_length(pstate->p_rtable) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_COLUMN_REFERENCE),
			errmsg("only table \"%s\" can be referenced in check constraint",
				   relname)));

	return expr;
}


/*
 * RemoveStatistics --- remove entries in pg_statistic for a rel or column
 *
 * If attnum is zero, remove all entries for rel; else remove only the one(s)
 * for that column.
 */
void
RemoveStatistics(Oid relid, AttrNumber attnum)
{
	Relation	pgstatistic;
	SysScanDesc scan;
	ScanKeyData key[2];
	int			nkeys;
	HeapTuple	tuple;

	pgstatistic = heap_open(StatisticRelationId, RowExclusiveLock);

	ScanKeyInit(&key[0],
				Anum_pg_statistic_starelid,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(relid));

	if (attnum == 0)
		nkeys = 1;
	else
	{
		ScanKeyInit(&key[1],
					Anum_pg_statistic_staattnum,
					BTEqualStrategyNumber, F_INT2EQ,
					Int16GetDatum(attnum));
		nkeys = 2;
	}

	scan = systable_beginscan(pgstatistic, StatisticRelidAttnumInhIndexId, true,
							  NULL, nkeys, key);

	/* we must loop even when attnum != 0, in case of inherited stats */
	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
		CatalogTupleDelete(pgstatistic, &tuple->t_self);

	systable_endscan(scan);

	heap_close(pgstatistic, RowExclusiveLock);
}


/*
 * RelationTruncateIndexes - truncate all indexes associated
 * with the heap relation to zero tuples.
 *
 * The routine will truncate and then reconstruct the indexes on
 * the specified relation.  Caller must hold exclusive lock on rel.
 */
static void
RelationTruncateIndexes(Relation heapRelation)
{
	ListCell   *indlist;

	/* Ask the relcache to produce a list of the indexes of the rel */
	foreach(indlist, RelationGetIndexList(heapRelation))
	{
		Oid			indexId = lfirst_oid(indlist);
		Relation	currentIndex;
		IndexInfo  *indexInfo;

		/* Open the index relation; use exclusive lock, just to be sure */
		currentIndex = index_open(indexId, AccessExclusiveLock);

		/*
		 * Fetch info needed for index_build.  Since we know there are no
		 * tuples that actually need indexing, we can use a dummy IndexInfo.
		 * This is slightly cheaper to build, but the real point is to avoid
		 * possibly running user-defined code in index expressions or
		 * predicates.  We might be getting invoked during ON COMMIT
		 * processing, and we don't want to run any such code then.
		 */
		indexInfo = BuildDummyIndexInfo(currentIndex);

		/* Now truncate the actual file (and discard buffers) */
		RelationTruncate(currentIndex, 0);

		/* Initialize the index and rebuild */
		/* Note: we do not need to re-establish pkey setting */
		index_build(heapRelation, currentIndex, indexInfo, false, true);

		/* We're done with this index */
		index_close(currentIndex, NoLock);
	}
}

/*
 *	 heap_truncate
 *
 *	 This routine deletes all data within all the specified relations.
 *
 * This is not transaction-safe!  There is another, transaction-safe
 * implementation in commands/tablecmds.c.  We now use this only for
 * ON COMMIT truncation of temporary tables, where it doesn't matter.
 */
void
heap_truncate(List *relids)
{
	List	   *relations = NIL;
	ListCell   *cell;

	/* Open relations for processing, and grab exclusive access on each */
	foreach(cell, relids)
	{
		Oid			rid = lfirst_oid(cell);
		Relation	rel;

		rel = heap_open(rid, AccessExclusiveLock);
		relations = lappend(relations, rel);
	}

	/* GPDB does not support all FK feature but keeps FK grammar recognition,
	 * which reduces migration manual workload from other databases.
	 * We do not want to reject relation truncate if the relation contains FK
	 * satisfied tuple, so skip heap_truncate_check_FKs function call.
	 */
#if 0
	/* Don't allow truncate on tables that are referenced by foreign keys */
	heap_truncate_check_FKs(relations, true);
#endif

	/* OK to do it */
	foreach(cell, relations)
	{
		Relation	rel = lfirst(cell);

		/* Truncate the relation */
		heap_truncate_one_rel(rel);

		/* Close the relation, but keep exclusive lock on it until commit */
		heap_close(rel, NoLock);
	}
}

/*
 *	 heap_truncate_one_relid
 *
 *	 This routine deletes all data within the specified relation.
 */
static void
heap_truncate_one_relid(Oid relid)
{
	if (OidIsValid(relid))
	{
		Relation rel = relation_open(relid, AccessExclusiveLock);
		heap_truncate_one_rel(rel);
		heap_close(rel, NoLock);
	}
}

static void
ao_aux_tables_truncate(Relation rel)
{
	Oid ao_base_relid = RelationGetRelid(rel);

	Oid			aoseg_relid = InvalidOid;
	Oid			aoblkdir_relid = InvalidOid;
	Oid			aovisimap_relid = InvalidOid;

	if (!RelationIsAppendOptimized(rel))
		return;

	GetAppendOnlyEntryAuxOids(ao_base_relid, NULL,
							  &aoseg_relid,
							  &aoblkdir_relid, NULL,
							  &aovisimap_relid, NULL);

	heap_truncate_one_relid(aoseg_relid);
	heap_truncate_one_relid(aoblkdir_relid);
	heap_truncate_one_relid(aovisimap_relid);
}

/*
 *	 heap_truncate_one_rel
 *
 *	 This routine deletes all data within the specified relation.
 *
 * This is not transaction-safe, because the truncation is done immediately
 * and cannot be rolled back later.  Caller is responsible for having
 * checked permissions etc, and must have obtained AccessExclusiveLock.
 */
void
heap_truncate_one_rel(Relation rel)
{
	Oid			toastrelid;

	/* Truncate the actual file (and discard buffers) */
	if (RelationIsAppendOptimized(rel))
	{
		ao_truncate_one_rel(rel);
		ao_aux_tables_truncate(rel);
	}
	else
		RelationTruncate(rel, 0);

	/* If the relation has indexes, truncate the indexes too */
	RelationTruncateIndexes(rel);

	/* If there is a toast table, truncate that too */
	toastrelid = rel->rd_rel->reltoastrelid;
	if (OidIsValid(toastrelid))
	{
		Relation	toastrel = heap_open(toastrelid, AccessExclusiveLock);

		RelationTruncate(toastrel, 0);
		RelationTruncateIndexes(toastrel);
		/* keep the lock... */
		heap_close(toastrel, NoLock);
	}
}

/*
 * heap_truncate_check_FKs
 *		Check for foreign keys referencing a list of relations that
 *		are to be truncated, and raise error if there are any
 *
 * We disallow such FKs (except self-referential ones) since the whole point
 * of TRUNCATE is to not scan the individual rows to be thrown away.
 *
 * This is split out so it can be shared by both implementations of truncate.
 * Caller should already hold a suitable lock on the relations.
 *
 * tempTables is only used to select an appropriate error message.
 */
void
heap_truncate_check_FKs(List *relations, bool tempTables)
{
	List	   *oids = NIL;
	List	   *dependents;
	ListCell   *cell;

	/*
	 * Build a list of OIDs of the interesting relations.
	 *
	 * If a relation has no triggers, then it can neither have FKs nor be
	 * referenced by a FK from another table, so we can ignore it.
	 */
	foreach(cell, relations)
	{
		Relation	rel = lfirst(cell);

		if (rel->rd_rel->relhastriggers)
			oids = lappend_oid(oids, RelationGetRelid(rel));
	}

	/*
	 * Fast path: if no relation has triggers, none has FKs either.
	 */
	if (oids == NIL)
		return;

	/*
	 * Otherwise, must scan pg_constraint.  We make one pass with all the
	 * relations considered; if this finds nothing, then all is well.
	 */
	dependents = heap_truncate_find_FKs(oids);
	if (dependents == NIL)
		return;

	/*
	 * Otherwise we repeat the scan once per relation to identify a particular
	 * pair of relations to complain about.  This is pretty slow, but
	 * performance shouldn't matter much in a failure path.  The reason for
	 * doing things this way is to ensure that the message produced is not
	 * dependent on chance row locations within pg_constraint.
	 */
	foreach(cell, oids)
	{
		Oid			relid = lfirst_oid(cell);
		ListCell   *cell2;

		dependents = heap_truncate_find_FKs(list_make1_oid(relid));

		foreach(cell2, dependents)
		{
			Oid			relid2 = lfirst_oid(cell2);

			if (!list_member_oid(oids, relid2))
			{
				char	   *relname = get_rel_name(relid);
				char	   *relname2 = get_rel_name(relid2);

				if (tempTables)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("unsupported ON COMMIT and foreign key combination"),
							 errdetail("Table \"%s\" references \"%s\", but they do not have the same ON COMMIT setting.",
									   relname2, relname)));
				else
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("cannot truncate a table referenced in a foreign key constraint"),
							 errdetail("Table \"%s\" references \"%s\".",
									   relname2, relname),
						   errhint("Truncate table \"%s\" at the same time, "
								   "or use TRUNCATE ... CASCADE.",
								   relname2)));
			}
		}
	}
}

/*
 * heap_truncate_find_FKs
 *		Find relations having foreign keys referencing any of the given rels
 *
 * Input and result are both lists of relation OIDs.  The result contains
 * no duplicates, does *not* include any rels that were already in the input
 * list, and is sorted in OID order.  (The last property is enforced mainly
 * to guarantee consistent behavior in the regression tests; we don't want
 * behavior to change depending on chance locations of rows in pg_constraint.)
 *
 * Note: caller should already have appropriate lock on all rels mentioned
 * in relationIds.  Since adding or dropping an FK requires exclusive lock
 * on both rels, this ensures that the answer will be stable.
 */
List *
heap_truncate_find_FKs(List *relationIds)
{
	List	   *result = NIL;
	Relation	fkeyRel;
	SysScanDesc fkeyScan;
	HeapTuple	tuple;

	/*
	 * Must scan pg_constraint.  Right now, it is a seqscan because there is
	 * no available index on confrelid.
	 */
	fkeyRel = heap_open(ConstraintRelationId, AccessShareLock);

	fkeyScan = systable_beginscan(fkeyRel, InvalidOid, false,
								  NULL, 0, NULL);

	while (HeapTupleIsValid(tuple = systable_getnext(fkeyScan)))
	{
		Form_pg_constraint con = (Form_pg_constraint) GETSTRUCT(tuple);

		/* Not a foreign key */
		if (con->contype != CONSTRAINT_FOREIGN)
			continue;

		/* Not referencing one of our list of tables */
		if (!list_member_oid(relationIds, con->confrelid))
			continue;

		/* Add referencer unless already in input or result list */
		if (!list_member_oid(relationIds, con->conrelid))
			result = insert_ordered_unique_oid(result, con->conrelid);
	}

	systable_endscan(fkeyScan);
	heap_close(fkeyRel, AccessShareLock);

	return result;
}

/*
 * insert_ordered_unique_oid
 *		Insert a new Oid into a sorted list of Oids, preserving ordering,
 *		and eliminating duplicates
 *
 * Building the ordered list this way is O(N^2), but with a pretty small
 * constant, so for the number of entries we expect it will probably be
 * faster than trying to apply qsort().  It seems unlikely someone would be
 * trying to truncate a table with thousands of dependent tables ...
 */
static List *
insert_ordered_unique_oid(List *list, Oid datum)
{
	ListCell   *prev;

	/* Does the datum belong at the front? */
	if (list == NIL || datum < linitial_oid(list))
		return lcons_oid(datum, list);
	/* Does it match the first entry? */
	if (datum == linitial_oid(list))
		return list;			/* duplicate, so don't insert */
	/* No, so find the entry it belongs after */
	prev = list_head(list);
	for (;;)
	{
		ListCell   *curr = lnext(prev);

		if (curr == NULL || datum < lfirst_oid(curr))
			break;				/* it belongs after 'prev', before 'curr' */

		if (datum == lfirst_oid(curr))
			return list;		/* duplicate, so don't insert */

		prev = curr;
	}
	/* Insert datum into list after 'prev' */
	lappend_cell_oid(list, prev, datum);
	return list;
}

/*
 * Note: when modifying this function, make sure to modify the query
 * updating 'relfrozenxid' in function set_frozenxids() too.
 * This is to keep consistent behavior for relfrozenxid before
 * and after upgrade.
 */
bool
should_have_valid_relfrozenxid(char relkind, char relstorage,
							   bool is_partition_parent)
{
	/*
	 * Parent tables in partition hierarchy (top or internal one) contains no
	 * data and hence no reason to have valid relfrozenxid.
	 */
	if (is_partition_parent)
		return false;

	switch (relkind)
	{
		case RELKIND_RELATION:
		case RELKIND_MATVIEW:
			if (relstorage == RELSTORAGE_EXTERNAL ||
				relstorage == RELSTORAGE_FOREIGN  ||
				relstorage == RELSTORAGE_VIRTUAL ||
				relstorage == RELSTORAGE_AOROWS ||
				relstorage == RELSTORAGE_AOCOLS)
			{
				return false;
			}
			return true;

		case RELKIND_TOASTVALUE:
		case RELKIND_AOSEGMENTS:
		case RELKIND_AOBLOCKDIR:
		case RELKIND_AOVISIMAP:
			return true;
	}

	return false;
}
