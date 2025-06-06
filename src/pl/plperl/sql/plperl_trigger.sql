-- test plperl triggers

CREATE TYPE rowcomp as (i int);
CREATE TYPE rowcompnest as (rfoo rowcomp);
CREATE TABLE trigger_test (
        i int,
        v varchar,
		foo rowcompnest
);

CREATE OR REPLACE FUNCTION trigger_data() RETURNS trigger LANGUAGE plperl AS $$

  # make sure keys are sorted for consistent results - perl no longer
  # hashes in  repeatable fashion across runs

  sub str {
	  my $val = shift;

	  if (!defined $val)
	  {
		  return 'NULL';
	  }
	  elsif (ref $val eq 'HASH')
	  {
		my $str = '';
		foreach my $rowkey (sort keys %$val)
		{
		  $str .= ", " if $str;
		  my $rowval = str($val->{$rowkey});
		  $str .= "'$rowkey' => $rowval";
		}
		return '{'. $str .'}';
	  }
	  elsif (ref $val eq 'ARRAY')
	  {
		  my $str = '';
		  for my $argval (@$val)
		  {
			  $str .= ", " if $str;
			  $str .= str($argval);
		  }
		  return '['. $str .']';
	  }
	  else
	  {
		  return "'$val'";
	  }
  }

  foreach my $key (sort keys %$_TD)
  {

    my $val = $_TD->{$key};

	# relid is variable, so we can not use it repeatably
	$val = "bogus:12345" if $key eq 'relid';

	elog(NOTICE, "\$_TD->\{$key\} = ". str($val));
  }
  return undef; # allow statement to proceed;
$$;

CREATE TRIGGER show_trigger_data_trig
BEFORE INSERT OR UPDATE OR DELETE ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE trigger_data(23,'skidoo');

insert into trigger_test values(1,'insert', '("(1)")');
update trigger_test set v = 'update' where i = 1;
delete from trigger_test;

DROP TRIGGER show_trigger_data_trig on trigger_test;

insert into trigger_test values(1,'insert', '("(1)")');
CREATE VIEW trigger_test_view AS SELECT * FROM trigger_test;

--start_ignore
-- INSTEAD OF triggers are not yet supported in Greengage
CREATE TRIGGER show_trigger_data_trig
INSTEAD OF INSERT OR UPDATE OR DELETE ON trigger_test_view
FOR EACH ROW EXECUTE PROCEDURE trigger_data(24,'skidoo view');

insert into trigger_test_view values(2,'insert', '("(2)")');
update trigger_test_view set v = 'update', foo = '("(3)")' where i = 1;
delete from trigger_test_view;
--end_ignore

DROP VIEW trigger_test_view;
delete from trigger_test;

DROP FUNCTION trigger_data();

CREATE OR REPLACE FUNCTION valid_id() RETURNS trigger AS $$

    if (($_TD->{new}{i}>=100) || ($_TD->{new}{i}<=0))
    {
        return "SKIP";   # Skip INSERT/UPDATE command
    }
    elsif ($_TD->{new}{v} ne "immortal")
    {
        $_TD->{new}{v} .= "(modified by trigger)";
		$_TD->{new}{foo}{rfoo}{i}++;
        return "MODIFY"; # Modify tuple and proceed INSERT/UPDATE command
    }
    else
    {
        return;          # Proceed INSERT/UPDATE command
    }
$$ LANGUAGE plperl;

CREATE TRIGGER "test_valid_id_trig" BEFORE INSERT OR UPDATE ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE "valid_id"();

INSERT INTO trigger_test (i, v, foo) VALUES (1,'first line', '("(1)")');
INSERT INTO trigger_test (i, v, foo) VALUES (2,'second line', '("(2)")');
INSERT INTO trigger_test (i, v, foo) VALUES (3,'third line', '("(3)")');
INSERT INTO trigger_test (i, v, foo) VALUES (4,'immortal', '("(4)")');

INSERT INTO trigger_test (i, v) VALUES (101,'bad id');

SELECT * FROM trigger_test;

UPDATE trigger_test SET i = 5 where i=3;

UPDATE trigger_test SET i = 100 where i=1;

SELECT * FROM trigger_test;

DROP TRIGGER "test_valid_id_trig" ON trigger_test;

CREATE OR REPLACE FUNCTION trigger_recurse() RETURNS trigger AS $$
	use strict;

	if ($_TD->{new}{i} == 10000)
	{
		spi_exec_query("insert into trigger_test (i, v) values (20000, 'child');");

		if ($_TD->{new}{i} != 10000)
		{
			die "recursive trigger modified: ". $_TD->{new}{i};
		}
	}
    return;
$$ LANGUAGE plperl;

CREATE TRIGGER "test_trigger_recurse" BEFORE INSERT ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE "trigger_recurse"();

INSERT INTO trigger_test (i, v) values (10000, 'top');

SELECT * FROM trigger_test;

CREATE OR REPLACE FUNCTION immortal() RETURNS trigger AS $$
    if ($_TD->{old}{v} eq $_TD->{args}[0])
    {
        return "SKIP"; # Skip DELETE command
    }
    else
    {
        return;        # Proceed DELETE command
    };
$$ LANGUAGE plperl;

CREATE TRIGGER "immortal_trig" BEFORE DELETE ON trigger_test
FOR EACH ROW EXECUTE PROCEDURE immortal('immortal');

DELETE FROM trigger_test;

SELECT * FROM trigger_test;

CREATE FUNCTION direct_trigger() RETURNS trigger AS $$
    return;
$$ LANGUAGE plperl;

SELECT direct_trigger();

-- test plperl command triggers
create or replace function perlsnitch() returns event_trigger language plperl as $$
  elog(NOTICE, "perlsnitch: " . $_TD->{event} . " " . $_TD->{tag} . " ");
$$;

create event trigger perl_a_snitch on ddl_command_start
   execute procedure perlsnitch();
create event trigger perl_b_snitch on ddl_command_end
   execute procedure perlsnitch();

create or replace function foobar() returns int language sql as $$select 1;$$;
alter function foobar() cost 77;
drop function foobar();

create table foo();
drop table foo;

drop event trigger perl_a_snitch;
drop event trigger perl_b_snitch;
