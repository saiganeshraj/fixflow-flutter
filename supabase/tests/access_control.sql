-- Run only against a disposable local/test Supabase database, via supabase test db.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email, raw_user_meta_data) values
('10000000-0000-0000-0000-000000000001','customer-a@example.invalid','{"display_name":"Customer A","role":"technician"}'),
('10000000-0000-0000-0000-000000000002','customer-b@example.invalid','{"display_name":"Customer B"}'),
('20000000-0000-0000-0000-000000000001','tech-a@example.invalid','{"display_name":"Tech A"}'),
('20000000-0000-0000-0000-000000000002','tech-b@example.invalid','{"display_name":"Tech B"}');
update public.profiles set role = 'technician' where id::text like '20000000%';
insert into public.technician_services(technician_id,service_id) values
('20000000-0000-0000-0000-000000000001','svc-pipe-repair'),
('20000000-0000-0000-0000-000000000001','svc-drain-unclog'),
('20000000-0000-0000-0000-000000000002','svc-fan-install');
select is((select role from public.profiles where id = '10000000-0000-0000-0000-000000000001'), 'customer', 'Signup metadata cannot grant technician role');
select ok(not has_table_privilege('authenticated','public.bookings','INSERT'), 'No direct booking insert');
select ok(not has_table_privilege('authenticated','public.bookings','UPDATE'), 'No direct status or price mutation');
select ok(not has_table_privilege('authenticated','public.profiles','UPDATE'), 'No role escalation');
select ok(not has_table_privilege('authenticated','public.booking_events','INSERT'), 'No forged timeline');
select ok(not has_function_privilege('anon','public.create_booking(text,timestamptz,text,text,text,text,text,text)','EXECUTE'), 'Anonymous booking rejected');

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001', true);
select set_config('fixflow.slot', (select slot_start_utc::text from public.available_slots('svc-pipe-repair') limit 1), true);
select set_config('fixflow.booking', public.create_booking('svc-pipe-repair',current_setting('fixflow.slot')::timestamptz,'10 Fictional Street','','Bengaluru','560001',null,'test-key')::text, true);
select is((select price_paise from public.bookings where id = current_setting('fixflow.booking')::uuid),149900,'Price from trusted catalog');
select is(public.create_booking('svc-pipe-repair',current_setting('fixflow.slot')::timestamptz,'20 Retry Street','','Bengaluru','560001',null,'test-key')::text,current_setting('fixflow.booking'),'Scoped retry returns original');
select throws_ok($$select public.create_booking('svc-drain-unclog',current_setting('fixflow.slot')::timestamptz,'10 Fictional Street','','Bengaluru','560001',null,'conflict')$$,'P0001',null,'Cross-service slot conflict');
select throws_ok($$select public.create_booking('svc-pipe-repair',now() - interval '1 day','10 Fictional Street','','Bengaluru','560001',null,'past')$$,'22023',null,'Past slot rejected');
select throws_ok($$select public.create_booking('svc-pipe-repair',now() + interval '20 days','10 Fictional Street','','Bengaluru','560001',null,'far')$$,'22023',null,'Outside horizon rejected');
select throws_ok($$select public.submit_review(current_setting('fixflow.booking')::uuid,5,null)$$,'22023',null,'Review requires completion');

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002', true);
select is((select count(*)::int from public.bookings),0,'Customer B cannot read A bookings');
select is((select count(*)::int from public.booking_events),0,'Customer B cannot read A timeline');
select throws_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'cancelled')$$,'42501',null,'Customer B cannot cancel A booking');
select throws_ok($$select public.submit_review(current_setting('fixflow.booking')::uuid,5,null)$$,'42501',null,'Customer B cannot review A booking');

select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000002', true);
select is((select count(*)::int from public.bookings),0,'Unassigned technician cannot read booking');
select throws_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'accepted')$$,'42501',null,'Wrong technician rejected');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001', true);
select throws_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'completed')$$,'22023',null,'Skipping stages rejected');
select lives_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'accepted')$$,'Assigned technician accepts');
select lives_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'accepted')$$,'Repeated acceptance safe');
select is((select count(*)::int from public.booking_events),2,'Repeated acceptance does not duplicate event');
select lives_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'en_route')$$,'Mark en route');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001', true);
select throws_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'cancelled')$$,'22023',null,'No cancellation after en route');
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001', true);
select lives_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'in_progress')$$,'Start service');
select lives_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'completed')$$,'Complete service');
select throws_ok($$select public.transition_booking(current_setting('fixflow.booking')::uuid,'accepted')$$,'22023',null,'Completed work terminal');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001', true);
select throws_ok($$select public.submit_review(current_setting('fixflow.booking')::uuid,6,null)$$,'22023',null,'Rating bounds');
select lives_ok($$select public.submit_review(current_setting('fixflow.booking')::uuid,5,'Good fictional service')$$,'Review completed work');
select throws_ok($$select public.submit_review(current_setting('fixflow.booking')::uuid,4,null)$$,'22023',null,'One review only');
select is((select count(*)::int from public.booking_events),5,'Review adds no status event');
select * from finish();
rollback;
