import asyncio
import websockets
import json
import os
import pprint

clients = {}

async def server(websocket,path):
    print("connection got")
    try:
        async for message in websocket:
            message = json.loads(message)
            print(message)

            clients[websocket] = message["User"]
            print(clients)
            if message["Mode"] == "Step" or message["Mode"] == "MapChange" or message["Mode"] == "Connect": #essentially replicate to all other clients
                for socket,name in clients.items():
                    if socket != websocket:
                        await socket.send(json.dumps(message))

    finally:
        print('fart 2')
        if websocket in clients:
            for socket,name in clients.items():
                if socket != websocket:
                    data = {"Mode": "Disconnect","User":clients[websocket],"Data":{}}
                    pprint(data)
                    await socket.send(json.dumps(data))

            del clients[websocket]
        
async def main():
    async with websockets.serve(server, "localhost", 2312):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())