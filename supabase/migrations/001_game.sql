create extension if not exists pgcrypto;
create table public.discoveries(id int primary key, label text not null, category text not null, emoji text not null, points int not null check(points>0), rarity text not null, regions text[] not null default '{}', seasons text[] not null default '{}', environments text[] not null default '{}', times text[] not null default '{}');
create table public.rooms(id uuid primary key default gen_random_uuid(), code text unique not null, host uuid not null, mode text not null check(mode in ('frenzy','blitz')), status text not null default 'lobby', region text not null, season text not null, environment text not null, daytime text not null, winner uuid, round int not null default 0, created_at timestamptz default now());
create table public.players(id uuid not null, room_id uuid references public.rooms on delete cascade, name text not null check(length(name) between 1 and 20), score int not null default 0, primary key(room_id,id));
create table public.cards(id uuid primary key default gen_random_uuid(), room_id uuid not null references public.rooms on delete cascade, player_id uuid not null, discovery_id int references public.discoveries, slot int not null, round int not null, claimed boolean not null default false);
create index on public.cards(room_id,player_id,round);
create index on public.players(id,room_id);
create index on public.cards(discovery_id);
alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.cards enable row level security;
alter table public.discoveries enable row level security;
create function public.member(r uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from players where room_id=r and id=auth.uid()) $$;
create policy room_read on public.rooms for select to authenticated using(public.member(id));
create policy player_read on public.players for select to authenticated using(public.member(room_id));
create policy card_read on public.cards for select to authenticated using(public.member(room_id) and player_id=auth.uid());
create policy discovery_read on public.discoveries for select to authenticated using(true);
revoke all on public.rooms,public.players,public.cards,public.discoveries from anon,authenticated;
grant select on public.rooms,public.players,public.cards,public.discoveries to authenticated;
create function public.eligible(d public.discoveries,r public.rooms) returns boolean language sql immutable set search_path=public as $$ select (cardinality(d.regions)=0 or r.region=any(d.regions)) and (cardinality(d.seasons)=0 or r.season=any(d.seasons)) and (cardinality(d.environments)=0 or r.environment=any(d.environments)) and (cardinality(d.times)=0 or r.daytime=any(d.times)) $$;
create function public.create_room(n text,m text,reg text,sea text,env text,tod text) returns uuid language plpgsql security definer set search_path=public as $$ declare rid uuid; c text; begin
if auth.uid() is null then raise exception 'Guest sign-in required'; end if;
if m not in ('frenzy','blitz') or reg not in ('midwest','northeast','southeast','southwest','west') or sea not in ('spring','summer','fall','winter') or env not in ('highway','rural','city') or tod not in ('day','night') then raise exception 'Invalid settings'; end if;
if (select count(*) from rooms where host=auth.uid() and created_at>now()-interval '1 hour')>=10 then raise exception 'Room limit reached'; end if;
loop c:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,6)); begin insert into rooms(code,host,mode,region,season,environment,daytime) values(c,auth.uid(),m,reg,sea,env,tod) returning id into rid; exit; exception when unique_violation then end; end loop;
insert into players(id,room_id,name) values(auth.uid(),rid,trim(n)); return rid; end $$;
create function public.join_room(c text,n text) returns uuid language plpgsql security definer set search_path=public as $$ declare r rooms; begin
if auth.uid() is null then raise exception 'Guest sign-in required'; end if;
select * into r from rooms where code=upper(trim(c)) for update;
if r.id is null then raise exception 'Room not found'; end if;
if exists(select 1 from players where room_id=r.id and id=auth.uid()) then return r.id; end if;
if r.status<>'lobby' then raise exception 'Game already started'; end if;
if (select count(*) from players where room_id=r.id)>=12 then raise exception 'Room full'; end if;
insert into players(id,room_id,name) values(auth.uid(),r.id,trim(n)); return r.id; end $$;
create function public.start_game(rid uuid) returns void language plpgsql security definer set search_path=public as $$ declare r rooms; p players; pool int[]; begin
select * into r from rooms where id=rid for update;
if r.host is distinct from auth.uid() then raise exception 'Host only'; end if;
if r.status not in ('lobby','finished') then raise exception 'Game already running'; end if;
if (select count(*) from players where room_id=rid)<2 then raise exception 'Invite at least one other player'; end if;
if (select count(*) from discoveries d where eligible(d,r))<16 then raise exception 'Not enough eligible discoveries'; end if;
update rooms set status='playing',winner=null,round=round+1 where id=rid returning * into r;
update players set score=0 where room_id=rid; delete from cards where room_id=rid;
select array_agg(id) into pool from (select d.id,row_number() over(partition by category order by random()) as rank from discoveries d where eligible(d,r) and d.points<=40 order by rank,random() limit case when r.mode='blitz' then 16 else 6 end) balanced;
for p in select * from players where room_id=rid loop
insert into cards(room_id,player_id,discovery_id,slot,round) select rid,p.id,x.id,row_number() over()-1,r.round from (select unnest(pool) as id order by random()) x;
end loop; end $$;
create function public.claim_card(cid uuid) returns void language plpgsql security definer set search_path=public as $$ declare r rooms; c cards; pts int; replacement int; total int; begin
select * into c from cards where id=cid;
if c.player_id is distinct from auth.uid() then raise exception 'Not your discovery'; end if;
select * into r from rooms where id=c.room_id for update;
select * into c from cards where id=cid for update;
if not found or c.claimed or c.round<>r.round or r.status<>'playing' then raise exception 'Discovery no longer available'; end if;
select points into pts from discoveries where id=c.discovery_id;
update cards set claimed=true where id=cid;
update players set score=score+pts where room_id=r.id and id=auth.uid() returning score into total;
if (r.mode='frenzy' and total>=500) or (r.mode='blitz' and not exists(select 1 from cards where room_id=r.id and player_id=auth.uid() and round=r.round and not claimed)) then
update rooms set status='finished',winner=auth.uid() where id=r.id;
elsif r.mode='frenzy' then
select d.id into replacement from discoveries d where eligible(d,r) and not exists(select 1 from cards b where b.room_id=r.id and b.player_id=auth.uid() and b.discovery_id=d.id and not b.claimed) and d.id<>c.discovery_id order by random() limit 1;
insert into cards(room_id,player_id,discovery_id,slot,round) values(r.id,auth.uid(),replacement,c.slot,r.round);
end if; end $$;
revoke execute on function public.member(uuid),public.eligible(public.discoveries,public.rooms),public.create_room(text,text,text,text,text,text),public.join_room(text,text),public.start_game(uuid),public.claim_card(uuid) from public,anon,authenticated;
grant execute on function public.member(uuid),public.create_room(text,text,text,text,text,text),public.join_room(text,text),public.start_game(uuid),public.claim_card(uuid) to authenticated;
alter publication supabase_realtime add table public.rooms,public.players,public.cards;
