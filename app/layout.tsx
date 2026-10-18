import './globals.css';
export const metadata={title:'RoadQuest · The adventure is out there',description:'Turn miles into memories. A multiplayer scavenger hunt for your next road trip.',manifest:'/manifest.webmanifest'};
export const viewport={width:'device-width',initialScale:1,themeColor:'#173f35'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
