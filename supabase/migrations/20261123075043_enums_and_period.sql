-- Base enum types and the period derivation function for P1.

create type public.user_role as enum ('admin', 'site_user');

create type public.certificate_status as enum (
  'draft',
  'in_review',
  'returned',
  'awaiting_signature',
  'approved'
);

create type public.attachment_kind as enum ('initial', 'signed');

-- Half of the month a date falls in: 1 for days 1..15, 2 for day 16 to month end.
create function public.period_half(d date)
returns smallint
language sql
immutable
strict
parallel safe
security invoker
set search_path = ''
as $$
  select case when extract(day from d) <= 15 then 1 else 2 end::smallint;
$$;

comment on function public.period_half(date) is
  'Returns 1 for days 1..15 and 2 for day 16 to the end of the month.';
