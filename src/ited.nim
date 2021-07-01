when isMainModule:
  import ws, asyncdispatch, asynchttpserver

  var connections = newSeq[WebSocket]()

  proc cb(req: Request) {.async, gcsafe.} =
    if req.url.path == "/":
      try:
        var ws = await newWebSocket(req)
        connections.add ws
        await ws.send("Well Come Two ItEd")

        while ws.readyState == Open:
          let packet = await ws.receiveStrPacket()
          for other in connections:
            if other.readyState == Open:
              asyncCheck other.send(packet)
      except WebSocketError:
        echo "socket closed:", getCurrentExceptionMsg()
    else:
      await req.respond(Http404, "Not Found")

  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), cb)

