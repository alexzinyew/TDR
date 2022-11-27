import asyncio
import websockets
import json

clients = {}

async def server(websocket,path):
    print("connection got")
    try:
        async for message in websocket:
            message = json.loads(message)

            clients[websocket] = message["User"]
            if message["Mode"] == "Step" or message["Mode"] == "MapChange" or message["Mode"] == "Connect" or message["Mode"] == "Chat": #essentially replicate to all other clients
                for socket,name in clients.items():
                    if socket != websocket:
                        await socket.send(json.dumps(message))

    finally:
        print('disconnect')
        if websocket in clients:
            for socket,name in clients.items():
                if socket != websocket:
                    data = {"Mode": "Disconnect","User":clients[websocket],"Data":{}}
                    await socket.send(json.dumps(data))

            del clients[websocket]
        
async def main():
    async with websockets.serve(server, "localhost", 2312):
        await asyncio.Future()

if __name__ == "__main__":
    asyncio.run(main())