@gpexpand
Feature: expand the cluster by adding more segments

    @gpexpand_no_mirrors
    @gpexpand_timing
    Scenario: after resuming a duration interrupted redistribution, tables are restored
	Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
	And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        And user has created expansiontest tables
        And 4000000 rows are inserted into table "expansiontest0" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest1" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest2" in schema "public" with column type list "int"
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
         And the user runs gpexpand to redistribute with duration "00:00:02"
        Then gpexpand should print "End time reached.  Stopping expansion." to stdout
        And verify that the cluster has 2 new segments
        When the user runs gpexpand to redistribute
        Then the tables have finished expanding
        And verify that the master pid has not been changed

    @gpexpand_no_mirrors
    @gpexpand_timing
    @gpexpand_standby
    Scenario: after a duration interrupted redistribution, state file on standby matches master
    	Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then user has created expansiontest tables
        And 4000000 rows are inserted into table "expansiontest0" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest1" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest2" in schema "public" with column type list "int"
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        When the user runs gpexpand to redistribute with duration "00:00:02"
        Then gpexpand should print "End time reached.  Stopping expansion." to stdout

    @gpexpand_no_mirrors
    @gpexpand_timing
    Scenario: after resuming an end time interrupted redistribution, tables are restored
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        And user has created expansiontest tables
        And 4000000 rows are inserted into table "expansiontest0" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest1" in schema "public" with column type list "int"
        And 4000000 rows are inserted into table "expansiontest2" in schema "public" with column type list "int"
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
         And the user runs gpexpand to redistribute with the --end flag
        Then gpexpand should print "End time reached.  Stopping expansion." to stdout
        And verify that the cluster has 2 new segments
        When the user runs gpexpand to redistribute
        Then the tables have finished expanding

    @gpexpand_no_mirrors
    @gpexpand_segment
    Scenario: expand a cluster that has no mirrors
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 2 new segments

    @gpexpand_no_mirrors
    @gpexpand_host
    Scenario: expand a cluster that has no mirrors with one new hosts
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2"
        And the new host "sdw2" is ready to go
        When the user runs gpexpand interview to add 0 new segment and 1 new host "sdw2"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 2 new segments

    @gpexpand_no_mirrors
    @gpexpand_host_and_segment
    Scenario: expand a cluster that has no mirrors with one new hosts
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2"
        And the new host "sdw2" is ready to go
        When the user runs gpexpand interview to add 1 new segment and 1 new host "sdw2"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 4 new segments

    @gpexpand_mirrors
    @gpexpand_segment
    Scenario: expand a cluster that has mirrors
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the number of segments have been saved
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors
        Then verify that the cluster has 4 new segments

    @gpexpand_mirrors
    @gpexpand_segment
    Scenario: expand a cluster that has mirrors and recover a failed segment
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the user runs gpexpand with a static inputfile for a two-node cluster with mirrors
        And expanded preferred primary on segment "3" has failed
        When the user runs "gprecoverseg -a"
        Then gprecoverseg should return a return code of 0
        And all the segments are running
        And the segments are synchronized
        When the user runs "gprecoverseg -ra"
        Then gprecoverseg should return a return code of 0
        And all the segments are running
        And the segments are synchronized

    @gpexpand_mirrors
    @gpexpand_host
    Scenario: expand a cluster that has mirrors with one new hosts
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2,sdw3"
        And the new host "sdw2,sdw3" is ready to go
        When the user runs gpexpand interview to add 0 new segment and 2 new host "sdw2,sdw3"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 8 new segments

    @gpexpand_mirrors
    @gpexpand_host_and_segment
    @gpexpand_standby
    Scenario: expand a cluster that has mirrors with one new host
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2,sdw3"
        And the new host "sdw2,sdw3" is ready to go
        When the user runs gpexpand interview to add 1 new segment and 2 new host "sdw2,sdw3"
       Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 14 new segments

    @gpexpand_mirrors
    @gpexpand_host_and_segment
    @gpexpand_standby
    Scenario: expand a cluster with tablespace that has mirrors with one new host
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
	And a tablespace is created with data
	And another tablespace is created with data
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2,sdw3"
        And the new host "sdw2,sdw3" is ready to go
        When the user runs gpexpand interview to add 1 new segment and 2 new host "sdw2,sdw3"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 14 new segments
	When the user runs gpexpand to redistribute
	Then the tablespace is valid after gpexpand

    @gpexpand_no_mirrors
    Scenario: expand a cluster with tablespace when there is no tablespace configuration file
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And a tablespace is created with data
        And another tablespace is created with data
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        And there are no gpexpand tablespace input configuration files
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 1
        And gpexpand should print "[WARNING]:-Could not locate tablespace input configuration file" escaped to stdout
        And gpexpand should print "A new tablespace input configuration file is written to" escaped to stdout
        And gpexpand should print "Please review the file and re-run with: gpexpand -i" escaped to stdout
        And verify if a gpexpand tablespace input configuration file is created
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        And verify that the cluster has 1 new segments
        And all the segments are running
        When the user runs gpexpand to redistribute
        Then the tablespace is valid after gpexpand

    @gpexpand_icproxy
    Scenario: Cluster expansion failed (no new proxy address) with IC proxy mode enabled
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is running in IC proxy mode
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 3
        And gpexpand should print "Checking ICProxy addresses failed" to stdout

    @gpexpand_icproxy
    Scenario: Cluster expansion failed (bind an wrong proxy address) with IC proxy mode enabled
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is running in IC proxy mode with new proxy address 4:2:cdw:16502
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 3
        And gpexpand should print "The ic_proxy process failed to bind or listen" to stdout

    @gpexpand_icproxy
    Scenario: Cluster expansion successful with IC proxy mode enabled
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is running in IC proxy mode with new proxy address 4:2:sdw1:16502
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 0

    @gpexpand_icproxy
    Scenario: Cluster expansion successful with IC proxy mode disabled (but proxy_addresses has been set)
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is not running in IC proxy mode, but proxy_addresses has been set
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 0
        And gpexpand should print "Recommended that run gpconfig to set gp_interconnect_proxy_addresses" to stdout

    @gpexpand_verify_redistribution
    Scenario: Verify data is correctly redistributed after expansion
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And the user connects to "gptest" with named connection "default"
        And the user executes "CREATE TEMP TABLE temp_t1 (c1 int) DISTRIBUTED BY (c1)" with named connection "default"
        And the user runs psql with "-c 'CREATE TABLE public.redistribute (i int) DISTRIBUTED BY (i)'" against database "gptest"
        And the user runs psql with "-c 'INSERT INTO public.redistribute SELECT generate_series(1, 10000)'" against database "gptest"
        And distribution information from table "public.redistribute" with data in "gptest" is saved
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        And the user drops the named connection "default"
        When the user runs gpexpand to redistribute
        Then distribution information from table "public.redistribute" with data in "gptest" is verified against saved data

    @gpexpand_verify_writable_external_redistribution
    Scenario: Verify policy of writable external table is correctly updated after redistribution
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And the user create a writable external table with name "ext_test"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        When the user runs gpexpand to redistribute
        Then the numsegments of table "ext_test" is 4

    @gpexpand_icw_db_concourse
    Scenario: Use a dump of the ICW database for expansion
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And the user runs psql with "-f /home/gpadmin/sqldump/dump.sql" against database "gptest"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1,sdw2,sdw3"
        And the new host "sdw2,sdw3" is ready to go
        And the user runs gpexpand interview to add 1 new segment and 2 new host "sdw2,sdw3"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        And verify that the cluster has 14 new segments

    @gpexpand_no_mirrors
    @gpexpand_no_restart
    @gpexpand_catalog_copied
    Scenario: expand a cluster without restarting db and catalog has been copied
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        And the number of segments have been saved
        And user has created test table
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then gpexpand should return a return code of 0
        And verify that the cluster has 2 new segments
        And all the segments are running
        And table "test" exists in "gptest" on specified segment sdw1:20502
        And table "test" exists in "gptest" on specified segment sdw1:20503
        And verify that the master pid has not been changed

    @gpexpand_no_mirrors
    @gpexpand_no_restart
    @gpexpand_conf_copied
    Scenario: expand a cluster without restarting db and conf has been copie
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then gpexpand should return a return code of 0
        And verify that the cluster has 1 new segments
        And all the segments are running
        And check segment conf: postgresql.conf
        And verify that the master pid has not been changed

    @gpexpand_no_mirrors
    @gpexpand_no_restart
    @gpexpand_long_run_read_only
    Scenario: expand a cluster without restarting db with long-run read-only transaction
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And user has created test table
        And 20 rows are inserted into table "test" in schema "public" with column type list "int"
        And a long-run read-only transaction exists on "test"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then gpexpand should return a return code of 0
        And verify that the cluster has 1 new segments
        And all the segments are running
        And verify that the master pid has not been changed
        And verify that long-run read-only transaction still exists on "test"

    @gpexpand_no_mirrors
    @gpexpand_no_restart
    @gpexpand_change_catalog_abort
    Scenario: expand a cluster without restarting db and any transaction which wants to change the catalog must be aborted
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And a long-run transaction starts
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then gpexpand should return a return code of 0
        And verify that the cluster has 1 new segments
        And all the segments are running
        And verify that the master pid has not been changed
        And verify that long-run transaction aborted for changing the catalog by creating table "test"

    @gpexpand_no_mirrors
    @gpexpand_no_restart
    @gpexpand_dml
    Scenario: expand a cluster without restarting db and any transaction which wants to do dml work well
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And the master pid has been saved
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw"
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignore.host"
        And the number of segments have been saved
        And the transactions are started for dml
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then gpexpand should return a return code of 0
        And verify that the cluster has 1 new segments
        And all the segments are running
        And verify that the master pid has not been changed
        And verify the dml results and commit
        And verify the dml results again in a new transaction
        When the user runs gpexpand to redistribute
        # Temporarily comment the verifys until redistribute is fixed. This allows us to commit a resource to get a dump of the ICW dump for other tests to use
        # Then distribution information from table "public.redistribute" with data in "gptest" is verified against saved data

    @gpexpand_mirrors
    @gpexpand_rollback
    Scenario: inject a fail and test if rollback is ok
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the gp_segment_configuration have been saved
        And set fault inject "gpexpand rollback test fault injection"
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors without ret code check
        Then gpexpand should return a return code of 3
        And run rollback
        And verify the gp_segment_configuration has been restored
        And unset fault inject
		# The rollback will remove the new segment's datadir, but this is not
		# enough to let it quit, it might stop immediately, it might stop after
		# tens of minutes.  If it does not quit in time, in later tests the new
		# segments might fail to be launched due to port conflicts.  So we must
		# force it to quit now.
        And the database is not running
        And the user runs remote command "pkill postgres || true" on host "sdw1"

    @gpexpand_no_mirrors
    @gpexpand_with_special_character
    Scenario: create database,schema,table with special character
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/tmp/gpexpand_behave'
        And the user runs command "rm -rf /tmp/gpexpand_behave/*"
        And a temporary directory under "/tmp/gpexpand_behave/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And create database schema table with special character
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the number of segments have been saved
        And the user runs gpexpand interview to add 1 new segment and 0 new host "ignored.host"
        When the user runs gpexpand with the latest gpexpand_inputfile without ret code check
        Then gpexpand should return a return code of 0
        And verify that the cluster has 1 new segments
        When the user runs gpexpand to redistribute
        Then the tables have finished expanding

    @gpexpand_mirrors
    @gpexpand_retry_failing_work_in_phase1_after_releasing_catalog_lock
    Scenario: inject a fail and test if retry is ok
    	Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And set fault inject "gpexpand retry after releaseing catalog lock fault injection"
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors without ret code check
        Then gpexpand should return a return code of 3
        And verify status file and gp_segment_configuration backup file exist on standby
        And unset fault inject
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors without ret code check
        Then gpexpand should return a return code of 0

    @gpexpand_verify_partition_external_table
    Scenario: Gpexpand should succeed when partition table contain an external table as child partition
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
		And database "gptest" exists
		And the user create an external table with name "ext_test" in partition table t
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        When the user runs gpexpand to redistribute
        Then the numsegments of table "ext_test" is 4

    @gpexpand_verify_matview
    Scenario: Gpexpand should succeed when expand materialized view
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And the user runs psql with "-c 'CREATE TABLE public.test_matview_base AS SELECT i FROM generate_series(1,10000) i DISTRIBUTED BY (i)'" against database "gptest"
        And the user runs psql with "-c 'CREATE MATERIALIZED VIEW public.test_matview as select * from public.test_matview_base DISTRIBUTED BY (i)'" against database "gptest"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        When the user runs gpexpand to redistribute
        Then the numsegments of table "public.test_matview" is 4
        And distribution information from table "public.test_matview" and "public.test_matview_base" in "gptest" are the same

    @gpexpand_verify_partition_table
    Scenario: Verify should succeed when expand partition table
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And the user create a partition table with name "partition_test"
        And distribution information from table "partition_test" with data in "gptest" is saved
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        When the user runs gpexpand to redistribute
        Then the numsegments of table "partition_test" is 4
        Then distribution information from table "partition_test" with data in "gptest" is verified against saved data

    @gpexpand_verify_partition_table_in_different_schemas
    Scenario: Verify should succeed when expand partition table placed in different schemas
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And schema "schema1" exists
        And schema "schema2" exists
        And the user create a partition table with name "schema1.partition_test"
        And the user sets schema of table "schema1.partition_test" to "schema2"
        And distribution information from table "schema2.partition_test" with data in "gptest" is saved
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 3 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 3 new segments
        When the user runs gpexpand to redistribute
        Then the numsegments of table "schema2.partition_test" is 4
        Then distribution information from table "schema2.partition_test" with data in "gptest" is verified against saved data

    @gpexpand_segment
    Scenario: on expand check if one or more cluster is down
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the primary on content 0 is stopped
        And user can start transactions
        And an FTS probe is triggered
        And the status of the primary on content 0 should be "d"
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors without ret code check
        Then gpexpand should return a return code of 0
        Then gpexpand should print "One or more segments are either down or not in preferred role." to stdout

    @gpexpand_segment
    Scenario: on expand check if one or more cluster is not in their preferred role
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And the user runs gpinitstandby with options " "
        And database "gptest" exists
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the primary on content 0 is stopped
        And user can start transactions
        And an FTS probe is triggered
        And the status of the primary on content 0 should be "d"
        When the user runs "gprecoverseg -a"
        Then gprecoverseg should return a return code of 0
        And all the segments are running
        And the segments are synchronized
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors without ret code check
        Then gpexpand should return a return code of 0
        And gpexpand should print "One or more segments are either down or not in preferred role." to stdout

    @gpexpand_no_mirrors
    @gpexpand_segment
    Scenario: expand a cluster and verify necessary catalog tables are copied to new segments
        Given the database is not running
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And the user runs psql with "-c 'CREATE ROLE abc; ALTER ROLE abc DENY DAY 0 DENY DAY 2 DENY BETWEEN DAY 4 AND DAY 5;'" against database "gptest"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 2 new segments
        And verify that "pg_description" catalog table is present on new segments
        And verify that "pg_shdescription" catalog table is present on new segments
        And verify that "pg_auth_time_constraint" catalog table is present on new segments
        When the user runs "gpcheckcat gptest"
        Then gpcheckcat should return a return code of 0
        And the user runs psql with "-c 'DROP ROLE abc'" against database "gptest"

    @gpexpand_mirrors
    @gpexpand_segment
    @gpexpand_verify_catalogs
    Scenario: expand a cluster that has mirrors and check that gpexpand does not copy extra data directories from master
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And the user runs command "analyzedb -d gptest -a"
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        And the number of segments have been saved
        When the user runs gpexpand with a static inputfile for a single-node cluster with mirrors
        Then verify that the cluster has 4 new segments
        And verify that the path "db_dumps" in each segment data directory does not exist
        And verify that the path "gpperfmon/data" in each segment data directory does not exist
        And verify that the path "gpperfmon/logs" in each segment data directory does not exist
        And verify that the path "promote" in each segment data directory does not exist
        And verify that the path "db_analyze" in each segment data directory does not exist

    @gpexpand_no_mirrors
    @gpexpand_segment
    @gpexpand_verify_dtx
    Scenario: Gpexpand should succeed when xlog has DTX info
        Given the database is not running
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And the user runs command "rm -rf /data/gpdata/gpexpand/*"
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "3" primaries only
        And database "gptest" exists
        And the user runs psql with "-c 'create extension IF NOT EXISTS gp_inject_fault;create table ttt(tc1 int);'" against database "gptest"
        And the user runs psql with "-c "SELECT gp_inject_fault('before_notify_commited_dtx_transaction', 'suspend', dbid) FROM gp_segment_configuration WHERE content = -1 AND role = 'p';"" against database "gptest"
        And the user runs the command "psql gptest -c 'insert into ttt select generate_series(1,100);'" in the background without sleep
        And waiting "1" seconds
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 1 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        And the user runs psql with "-c "SELECT gp_inject_fault('before_notify_commited_dtx_transaction', 'reset', dbid) FROM gp_segment_configuration WHERE content = -1 AND role = 'p';"" against database "gptest"
        And waiting "1" seconds
        And the user runs psql with "-c 'drop table ttt;'" against database "gptest"
        Then verify that the cluster has 1 new segments

    @gpexpand_no_mirrors
    @gpexpand_segment
    Scenario: gpexpand should skip already expanded/broken tables when redistributing
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And a cluster is created with no mirrors on "cdw" and "sdw1"
        And database "gptest" exists
        And the user runs psql with "-c 'CREATE TABLE test_good_1(a int)'" against database "gptest"
        And the user runs psql with "-c 'CREATE TABLE test_already_expanded(a int)'" against database "gptest"
        And the user runs psql with "-c 'CREATE TABLE test_broken(a int)'" against database "gptest"
        And the user runs psql with "-c 'CREATE TABLE test_good_2(a int)'" against database "gptest"
        And the user runs sql "DROP TABLE test_broken" in "gptest" on primary segment with content 0
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "cdw,sdw1"
        When the user runs gpexpand interview to add 2 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--silent"
        Then verify that the cluster has 2 new segments
        And the user runs psql with "-c 'ALTER TABLE test_already_expanded expand table'" against database "gptest"
        When the user runs gpexpand to redistribute
        Then gpexpand should print "[WARNING]:-Encountered unexpected issue when expanding table gptest.public.test_broken, skipping" escaped to stdout
        And gpexpand should print "[INFO]:-Table gptest.public.test_already_expanded seems to be already expanded, marking as done" escaped to stdout
        And table "test_good_1" should be marked as expanded
        And table "test_good_2" should be marked as expanded
        And table "test_already_expanded" should be marked as expanded
        And table "test_broken" should not be marked as expanded

    @gpexpand_avoid_tarfile_overwrite
    Scenario: Avoid overwriting the tar file on coordinator
        Given the database is not running
        # need to remove this log because otherwise SCAN_LOG may pick up a previous error/warning in the log
        And the user runs command "rm -rf ~/gpAdminLogs/gpinitsystem*"
        # gpconfigurenewsegment scp's tar file to home by default
        And a working directory of the test as '/data/gpdata/gpexpand'
        And a temporary directory under "/data/gpdata/gpexpand/expandedData" to expand into
        And the cluster is generated with "1" primaries only
        And database "gptest" exists
        And the directory is changed to '/home/gpadmin'
        And there are no gpexpand_inputfiles
        And the cluster is setup for an expansion on hosts "localhost"
        When the user runs gpexpand interview to add 1 new segment and 0 new host "ignored.host"
        Then the number of segments have been saved
        When the user runs gpexpand with the latest gpexpand_inputfile with additional parameters "--verbose"
        Then gpexpand should print "[DEBUG]:-Skipping tar file (gpexpand_schema.tar) copy to cdw" escaped to stdout
        And verify that the cluster has 1 new segments
