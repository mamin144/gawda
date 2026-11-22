begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(2);

select has_extension('pgtap');
select has_schema('tests');

select * from finish();
rollback;
