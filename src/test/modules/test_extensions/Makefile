# src/test/modules/test_extensions/Makefile

MODULE = test_extensions
PGFILEDESC = "test_extensions - regression testing for EXTENSION support"

EXTENSION = test_ext_cor test_ext_cine test_ext_cau \
            test_ext_extschema test_ext_ao
DATA = test_ext_cor--1.0.sql test_ext_cine--1.0.sql test_ext_cine--1.0--1.1.sql \
       test_ext_cau--1.0--1.1.sql test_ext_cau--1.0.sql \
       test_ext_cau--1.1.sql test_ext_cau--unpackaged--1.0.sql \
       test_ext_extschema--1.0.sql test_ext_ao--1.0.sql

REGRESS = test_extensions

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = src/test/modules/test_extensions
top_builddir = ../../../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

installcheck: install
test: clean all install
	psql postgres -f sql/test_extensions.sql 2>&1
