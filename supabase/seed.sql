insert into public.categories(id,name,icon_name) values
('cat-plumbing','Plumbing','plumbing'),('cat-electrical','Electrical','electrical_services'),('cat-cleaning','Cleaning','cleaning_services');
insert into public.services(id,category_id,title,description,inclusions,price_paise) values
('svc-pipe-repair','cat-plumbing','Pipe Leak Repair','Fictional leak diagnosis, pipe repair and pressure testing.','["Leak diagnosis","Pipe repair","Pressure test"]',149900),
('svc-drain-unclog','cat-plumbing','Drain Unclogging','Fictional drain inspection, cleaning and flush testing.','["Drain inspection","Blockage removal","Flush test"]',99900),
('svc-fan-install','cat-electrical','Ceiling Fan Installation','Fictional fan installation, wiring and safety testing.','["Mounting","Wiring","Safety test"]',79900),
('svc-switchboard','cat-electrical','Switchboard Repair','Fictional switch and socket diagnosis and repair.','["Fault diagnosis","Switch replacement","Wiring inspection"]',129900),
('svc-deep-clean','cat-cleaning','Deep Home Cleaning','Fictional kitchen, bathroom and living area cleaning.','["Kitchen cleaning","Bathroom cleaning","Floor cleaning"]',199900),
('svc-sofa-clean','cat-cleaning','Sofa & Upholstery Cleaning','Fictional fabric inspection, steam cleaning and deodorising.','["Fabric inspection","Steam cleaning","Deodorising"]',159900);
-- Auth accounts and technicians are deliberately not seeded with passwords.
-- Provision test technicians following docs/BACKEND.md.
