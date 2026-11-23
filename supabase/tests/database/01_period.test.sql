begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(18);

-- Enum types and their exact label order.
select has_type('public', 'user_role', 'type public.user_role exists');
select enum_has_labels(
  'public', 'user_role',
  array['admin', 'site_user'],
  'user_role labels are exact and ordered'
);

select has_type('public', 'certificate_status', 'type public.certificate_status exists');
select enum_has_labels(
  'public', 'certificate_status',
  array['draft', 'in_review', 'returned', 'awaiting_signature', 'approved'],
  'certificate_status labels are exact and ordered'
);

select has_type('public', 'attachment_kind', 'type public.attachment_kind exists');
select enum_has_labels(
  'public', 'attachment_kind',
  array['initial', 'signed'],
  'attachment_kind labels are exact and ordered'
);

-- Function signature and volatility.
select function_returns(
  'public', 'period_half', array['date'], 'smallint',
  'period_half(date) returns smallint'
);
select volatility_is(
  'public', 'period_half', array['date'], 'immutable',
  'period_half(date) is immutable'
);

-- First half: days 1..15.
select is(public.period_half('2025-01-01'::date), 1::smallint, '2025-01-01 is half 1');
select is(public.period_half('2025-01-15'::date), 1::smallint, '2025-01-15 is half 1');
select is(public.period_half('2024-02-15'::date), 1::smallint, '2024-02-15 is half 1');

-- Second half: day 16 to the end of the month, for every month length.
select is(public.period_half('2025-01-16'::date), 2::smallint, '2025-01-16 is half 2');
select is(public.period_half('2025-01-31'::date), 2::smallint, '2025-01-31 (31-day month) is half 2');
select is(public.period_half('2025-04-30'::date), 2::smallint, '2025-04-30 (30-day month) is half 2');
select is(public.period_half('2025-02-28'::date), 2::smallint, '2025-02-28 (28-day month) is half 2');
select is(public.period_half('2024-02-29'::date), 2::smallint, '2024-02-29 (29-day month) is half 2');
select is(public.period_half('2025-02-16'::date), 2::smallint, '2025-02-16 is half 2');

-- Strict: null in, null out.
select is(public.period_half(null::date), null::smallint, 'period_half(null) is null');

select * from finish();
rollback;
