import {createClient} from '@supabase/supabase-js';
import assert from 'node:assert/strict';
const key=process.env.RQ_PUBLIC_KEY||process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,url=process.env.RQ_SUPABASE_URL||process.env.NEXT_PUBLIC_SUPABASE_URL;
if(!key||!url)throw Error('Set RQ_SUPABASE_URL and RQ_PUBLIC_KEY for the dedicated test project. This test creates guest users and rooms.');
const client=()=>createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
const a=client(),b=client();let channel;
async function ok(p){const r=await p;if(r.error)throw r.error;return r.data}
const log=s=>console.log('PASS '+s);
try{
await ok(a.auth.signInAnonymously());await ok(b.auth.signInAnonymously());const au=(await a.auth.getUser()).data.user.id,bu=(await b.auth.getUser()).data.user.id;assert.notEqual(au,bu);log('independent guest identities');
const rid=await ok(a.rpc('create_room',{n:'QA host',m:'frenzy',reg:'midwest',sea:'fall',env:'highway',tod:'day'}));const room=await ok(a.from('rooms').select('*').eq('id',rid).single());await ok(b.rpc('join_room',{c:room.code,n:'QA guest'}));log('room creation and code join');
let events=0;channel=b.channel('qa-'+rid).on('postgres_changes',{event:'UPDATE',schema:'public',table:'players',filter:'room_id=eq.'+rid},()=>events++);
await new Promise((resolve,reject)=>{const timeout=setTimeout(()=>reject(Error('Realtime subscribe timeout')),15000);channel.subscribe(s=>{if(s==='SUBSCRIBED'){clearTimeout(timeout);resolve()}else if(s==='CHANNEL_ERROR'){clearTimeout(timeout);reject(Error('Realtime channel error'))}})});
assert.ok((await b.rpc('start_game',{rid})).error);await ok(a.rpc('start_game',{rid}));log('host-only start');
const cards=await ok(a.from('cards').select('*').eq('room_id',rid).eq('claimed',false));assert.equal(cards.length,6);assert.ok(cards.every(c=>c.player_id===au));const c=cards[0];const d=await ok(a.from('discoveries').select('points').eq('id',c.discovery_id).single());
assert.ok((await b.rpc('claim_card',{cid:c.id})).error);const claims=await Promise.all([a.rpc('claim_card',{cid:c.id}),a.rpc('claim_card',{cid:c.id})]);assert.equal(claims.filter(x=>!x.error).length,1);const player=await ok(a.from('players').select('*').eq('room_id',rid).eq('id',au).single());assert.equal(player.score,d.points);log('simultaneous duplicate submission scores exactly once; cross-player claim rejected');
await new Promise(r=>setTimeout(r,1500));assert.ok(events>0);log('cross-session Realtime leaderboard events');
const sess=(await a.auth.getSession()).data.session;const reconnected=client();await ok(reconnected.auth.setSession({access_token:sess.access_token,refresh_token:sess.refresh_token}));const restored=await ok(reconnected.from('players').select('*').eq('room_id',rid).eq('id',au).single());assert.equal(restored.score,player.score);log('fresh client restores session and persisted score');
for(let i=0;i<40;i++){const r=await ok(a.from('rooms').select('*').eq('id',rid).single());if(r.status==='finished')break;const cs=await ok(a.from('cards').select('*').eq('room_id',rid).eq('claimed',false).limit(1));await ok(a.rpc('claim_card',{cid:cs[0].id}));}
const win=await ok(b.from('rooms').select('*').eq('id',rid).single());assert.equal(win.status,'finished');assert.equal(win.winner,au);assert.ok((await a.rpc('claim_card',{cid:c.id})).error);await ok(a.rpc('start_game',{rid}));const reset=await ok(b.from('players').select('*').eq('room_id',rid));assert.ok(reset.every(p=>p.score===0));log('Frenzy winner shared across sessions, post-win rejection and rematch');
const br=await ok(a.rpc('create_room',{n:'QA host',m:'blitz',reg:'midwest',sea:'fall',env:'highway',tod:'day'}));const brr=await ok(a.from('rooms').select('*').eq('id',br).single());await ok(b.rpc('join_room',{c:brr.code,n:'QA guest'}));await ok(a.rpc('start_game',{rid:br}));const bc=await ok(b.from('cards').select('*').eq('room_id',br));assert.equal(bc.length,16);for(const c of bc)await ok(b.rpc('claim_card',{cid:c.id}));const bw=await ok(a.from('rooms').select('*').eq('id',br).single());assert.equal(bw.winner,bu);assert.equal(bw.status,'finished');log('Board Blitz 16-card win visible to other guest');
console.log('LIVE API MULTIPLAYER VERIFIED. Browser and offline-network UI testing still pending.');
}catch(e){console.error('FAIL',e.message);process.exitCode=1}finally{if(channel)await b.removeChannel(channel);await a.removeAllChannels();await b.removeAllChannels();process.exit(process.exitCode||0)}
