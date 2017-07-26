local client = require "resty.websocket.client"
local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("Websockets", function()
  -- Pending (2017/06/16)
  -- Since sockb.in appears to be offline, we'll need to find a way to test
  -- WebSocket proxying support differently.
  --  * Use another service
  --  * Spawn our own sockb.in instance on Heroku
  --  * Compile our test Nginx with the stream module for local testing (ideal)

  setup(function()
    assert(helpers.dao.apis:insert {
      name = "ws",
      uris = { "/ws" },
      strip_uri = true,
      upstream_url = "http://127.0.0.1:55555"
    })

    assert(helpers.start_kong({nginx_conf = "spec/fixtures/custom_nginx.template"}))
  end)

  teardown(function()
    helpers.stop_kong()
  end)

  local function make_request(uri)
    local wb = assert(client:new())
    assert(wb:connect(uri))
    assert(wb:send_text('{"message": "hello websocket"}'))

    local frame = assert(wb:recv_frame())
    assert.equal("hello websocket", cjson.decode(frame).message)

    assert(wb:send_close())

    return true
  end

  it("works without Kong", function()
    assert(make_request("ws://127.0.0.1:55555/"))
  end)

  it("works with Kong", function()
    assert(make_request("ws://" .. helpers.test_conf.proxy_ip .. ":" .. helpers.test_conf.proxy_port .. "/ws"))
  end)

  it("works with Kong under HTTPS", function()
    assert(make_request("wss://" .. helpers.test_conf.proxy_ssl_ip .. ":" .. helpers.test_conf.proxy_ssl_port .. "/ws"))
  end)
end)
