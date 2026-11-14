-- Development schema. Apply with Supabase migrations, never against production without review.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  role text not null default 'customer' check (role in ('customer', 'technician'))
);
create table public.categories (id text primary key, name text not null, icon_name text not null);
create table public.services (
  id text primary key, category_id text not null references public.categories,
  title text not null, description text not null, inclusions jsonb not null default '[]',
  price_paise integer not null check (price_paise >= 0), active boolean not null default true
);
create table public.technician_services (
  technician_id uuid references public.profiles on delete cascade,
  service_id text references public.services, primary key (technician_id, service_id)
);
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles,
  technician_id uuid not null references public.profiles,
  service_id text not null references public.services,
  slot_start_utc timestamptz not null,
  address_line1 text not null check (char_length(address_line1) between 5 and 200),
  address_line2 text not null default '' check (char_length(address_line2) <= 200),
  city text not null check (char_length(city) between 1 and 80),
  pincode text not null check (pincode ~ '^[1-9][0-9]{5}$'),
  notes text check (char_length(notes) <= 500),
  price_paise integer not null check (price_paise >= 0),
  status text not null default 'requested' check (status in ('requested','accepted','en_route','in_progress','completed','cancelled')),
  idempotency_key text not null check (char_length(idempotency_key) between 1 and 100),
  created_at timestamptz not null default now(),
  unique (customer_id, idempotency_key)
);
-- All appointments start on an hourly service-zone boundary. Completed work
-- keeps its reservation; only cancellation frees a slot.
create unique index technician_slot_reservation on public.bookings (technician_id, slot_start_utc) where status <> 'cancelled';
create index bookings_customer on public.bookings(customer_id, created_at desc);
create index bookings_technician on public.bookings(technician_id, slot_start_utc);
create table public.booking_events (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null references public.bookings,
  previous_status text, new_status text not null, actor_id uuid not null references public.profiles,
  occurred_at timestamptz not null default now()
);
create index booking_events_booking on public.booking_events(booking_id, occurred_at);
create table public.reviews (
  id uuid primary key default gen_random_uuid(), booking_id uuid not null unique references public.bookings,
  customer_id uuid not null references public.profiles, rating integer not null check (rating between 1 and 5),
  comment text check (char_length(comment) <= 500), created_at timestamptz not null default now()
);

create function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id, display_name, role)
  values (new.id, left(coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), 'Customer'), 80), 'customer');
  return new;
end; $$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.services enable row level security;
alter table public.technician_services enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_events enable row level security;
alter table public.reviews enable row level security;

create policy catalog_categories on public.categories for select to anon, authenticated using (true);
create policy catalog_services on public.services for select to anon, authenticated using (active);
create policy scoped_bookings on public.bookings for select to authenticated using (customer_id = (select auth.uid()) or technician_id = (select auth.uid()));
create policy scoped_profiles on public.profiles for select to authenticated using (
  id = (select auth.uid()) or exists (select 1 from public.bookings b where b.technician_id = profiles.id and b.customer_id = (select auth.uid()))
);
create policy scoped_eligibility on public.technician_services for select to authenticated using (
  technician_id = (select auth.uid()) or exists (select 1 from public.bookings b where b.technician_id = technician_services.technician_id and b.customer_id = (select auth.uid()))
);
create policy scoped_events on public.booking_events for select to authenticated using (exists (
  select 1 from public.bookings b where b.id = booking_id and (b.customer_id = (select auth.uid()) or b.technician_id = (select auth.uid()))
));
create policy scoped_reviews on public.reviews for select to authenticated using (exists (
  select 1 from public.bookings b where b.id = booking_id and (b.customer_id = (select auth.uid()) or b.technician_id = (select auth.uid()))
));

revoke all on public.profiles, public.categories, public.services, public.technician_services, public.bookings, public.booking_events, public.reviews from public, anon, authenticated;
grant select on public.categories, public.services to anon, authenticated;
grant select on public.profiles, public.technician_services, public.bookings, public.booking_events, public.reviews to authenticated;

create function public.available_slots(p_service_id text) returns table(slot_start_utc timestamptz)
language sql stable security definer set search_path = '' as $$
  select (d.day + h.hour * interval '1 hour') at time zone 'Asia/Kolkata'
  from generate_series(date_trunc('day', now() at time zone 'Asia/Kolkata'), date_trunc('day', now() at time zone 'Asia/Kolkata') + interval '6 days', interval '1 day') d(day)
  cross join generate_series(9, 16) h(hour)
  where (d.day + h.hour * interval '1 hour') at time zone 'Asia/Kolkata' > now()
  and exists (select 1 from public.services s where s.id = p_service_id and s.active)
  and exists (
    select 1 from public.technician_services ts join public.profiles p on p.id = ts.technician_id
    where ts.service_id = p_service_id and p.role = 'technician' and not exists (
      select 1 from public.bookings b where b.technician_id = ts.technician_id
      and b.status <> 'cancelled' and b.slot_start_utc = (d.day + h.hour * interval '1 hour') at time zone 'Asia/Kolkata'
    )
  ) order by 1;
$$;
revoke all on function public.available_slots(text) from public, anon;
grant execute on function public.available_slots(text) to authenticated;

create function public.create_booking(p_service_id text, p_slot_start_utc timestamptz,
  p_address_line1 text, p_address_line2 text, p_city text, p_pincode text, p_notes text, p_idempotency_key text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  actor uuid := auth.uid(); existing uuid; tech uuid; candidate uuid; trusted_price integer;
  slot_local timestamp := p_slot_start_utc at time zone 'Asia/Kolkata'; result_id uuid;
begin
  if actor is null or not exists (select 1 from public.profiles where id = actor and role = 'customer') then
    raise exception 'Customer account required' using errcode = '42501';
  end if;
  if p_idempotency_key is null or char_length(btrim(p_idempotency_key)) not between 1 and 100 then
    raise exception 'Invalid request key' using errcode = '22023';
  end if;
  -- Serialize scoped retries before reading; hash collisions only add contention.
  perform pg_advisory_xact_lock(hashtextextended(actor::text || ':' || p_idempotency_key, 0));
  select id into existing from public.bookings where customer_id = actor and idempotency_key = p_idempotency_key;
  if found then return existing; end if;
  if p_slot_start_utc is null or p_slot_start_utc <= now()
    or slot_local::date < (now() at time zone 'Asia/Kolkata')::date
    or slot_local::date > (now() at time zone 'Asia/Kolkata')::date + 6
    or extract(hour from slot_local) not between 9 and 16
    or date_trunc('hour', slot_local) <> slot_local then
    raise exception 'Choose an available future hourly slot within seven service days' using errcode = '22023';
  end if;
  if p_address_line1 is null or char_length(btrim(p_address_line1)) not between 5 and 200
    or char_length(coalesce(btrim(p_address_line2), '')) > 200
    or p_city is null or char_length(btrim(p_city)) not between 1 and 80
    or p_pincode is null or btrim(p_pincode) !~ '^[1-9][0-9]{5}$'
    or char_length(coalesce(btrim(p_notes), '')) > 500 then
    raise exception 'Check address, pincode and notes' using errcode = '22023';
  end if;
  select price_paise into trusted_price from public.services where id = p_service_id and active;
  if not found then raise exception 'Service unavailable' using errcode = '22023'; end if;
  -- Lock technicians in deterministic order. Concurrent bookings for different
  -- services share these same locks. The unique index is a final race guard.
  for candidate in select p.id from public.profiles p join public.technician_services ts on ts.technician_id = p.id
    where ts.service_id = p_service_id and p.role = 'technician' order by p.id for update of p loop
    if not exists (select 1 from public.bookings where technician_id = candidate and slot_start_utc = p_slot_start_utc and status <> 'cancelled') then
      tech := candidate; exit;
    end if;
  end loop;
  if tech is null then raise exception 'No technician available for this slot' using errcode = 'P0001'; end if;
  insert into public.bookings(customer_id, technician_id, service_id, slot_start_utc, address_line1, address_line2, city, pincode, notes, price_paise, idempotency_key)
    values(actor, tech, p_service_id, p_slot_start_utc, btrim(p_address_line1), coalesce(btrim(p_address_line2), ''), btrim(p_city), btrim(p_pincode), nullif(btrim(p_notes), ''), trusted_price, p_idempotency_key)
    returning id into result_id;
  insert into public.booking_events(booking_id, new_status, actor_id) values(result_id, 'requested', actor);
  return result_id;
end; $$;
revoke all on function public.create_booking(text,timestamptz,text,text,text,text,text,text) from public, anon;
grant execute on function public.create_booking(text,timestamptz,text,text,text,text,text,text) to authenticated;

create function public.transition_booking(p_booking_id uuid, p_status text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor uuid := auth.uid(); b public.bookings; expected text;
begin
  if actor is null then raise exception 'Sign in required' using errcode = '42501'; end if;
  select * into b from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking unavailable' using errcode = '42501'; end if;
  if p_status = 'cancelled' then
    if b.customer_id <> actor then raise exception 'Not your booking' using errcode = '42501'; end if;
    if b.status = 'cancelled' then return b.id; end if;
    if b.status not in ('requested','accepted') then raise exception 'Cancellation is no longer available' using errcode = '22023'; end if;
  else
    if b.technician_id <> actor or not exists (select 1 from public.profiles where id = actor and role = 'technician') then
      raise exception 'Assigned technician required' using errcode = '42501';
    end if;
    if p_status not in ('accepted','en_route','in_progress','completed') or p_status is null then
      raise exception 'Invalid status' using errcode = '22023';
    end if;
    if b.status = p_status then return b.id; end if;
    expected := case p_status when 'accepted' then 'requested' when 'en_route' then 'accepted' when 'in_progress' then 'en_route' when 'completed' then 'in_progress' end;
    if b.status <> expected then raise exception 'Cannot skip job stages' using errcode = '22023'; end if;
  end if;
  update public.bookings set status = p_status where id = b.id;
  insert into public.booking_events(booking_id, previous_status, new_status, actor_id) values(b.id, b.status, p_status, actor);
  return b.id;
end; $$;
revoke all on function public.transition_booking(uuid,text) from public, anon;
grant execute on function public.transition_booking(uuid,text) to authenticated;

create function public.submit_review(p_booking_id uuid, p_rating integer, p_comment text default null) returns uuid
language plpgsql security definer set search_path = '' as $$
declare actor uuid := auth.uid(); b public.bookings;
begin
  select * into b from public.bookings where id = p_booking_id for update;
  if actor is null or not found or b.customer_id <> actor then raise exception 'Not your booking' using errcode = '42501'; end if;
  if b.status <> 'completed' or p_rating is null or p_rating not between 1 and 5 or char_length(coalesce(btrim(p_comment),'')) > 500 then
    raise exception 'Review requires completed work, rating 1–5 and up to 500 characters' using errcode = '22023';
  end if;
  if exists (select 1 from public.reviews where booking_id = b.id) then raise exception 'Already reviewed' using errcode = '22023'; end if;
  insert into public.reviews(booking_id, customer_id, rating, comment) values(b.id, actor, p_rating, nullif(btrim(p_comment),''));
  return b.id;
end; $$;
revoke all on function public.submit_review(uuid,integer,text) from public, anon;
grant execute on function public.submit_review(uuid,integer,text) to authenticated;
