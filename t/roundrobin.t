# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

$ENV{TEST_NGINX_CWD} = $pwd;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "$pwd/?.so;;";
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            math.randomseed(75098)

            local roundrobin = require "resty.roundrobin"

            local servers = {
                ["server1"] = 8,
                ["server2"] = 4,
                ["server3"] = 2,
            }

            local rr = roundrobin:new(servers)

            ngx.say("gcd: ", rr.gcd)

            for i = 1, 14 do
                local id = rr:find()
                if type(id) ~= "string" or not servers[id] then
                    return ngx.say("fail")
                end
            end

            ngx.say("success")
        }
    }
--- request
GET /t
--- response_body
gcd: 2
success
--- no_error_log
[error]



=== TEST 2: find count
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            math.randomseed(75098)

            local roundrobin = require "resty.roundrobin"

            local servers = {
                ["server1"] = 6,
                ["server2"] = 3,
                ["server3"] = 1,
            }

            local rr = roundrobin:new(servers)

            local res = {}
            for i = 1, 100 * 1000 do
                local id = rr:find()

                if res[id] then
                    res[id] = res[id] + 1
                else
                    res[id] = 1
                end
            end

            local keys = {}
            for id, num in pairs(res) do
                keys[#keys + 1] = id
            end

            if #keys ~= 3 then
                ngx.exit(400)
            end

            ngx.say("server1: ", res['server1'])
            ngx.say("server2: ", res['server2'])
            ngx.say("server3: ", res['server3'])
        }
    }
--- request
GET /t
--- response_body
server1: 60000
server2: 30000
server3: 10000
--- no_error_log
[error]



=== TEST 3: random start
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            math.randomseed(9975098)

            local roundrobin = require "resty.roundrobin"

            local servers = {
                ["server1"] = 1,
                ["server2"] = 1,
                ["server3"] = 1,
                ["server4"] = 1,
            }

            local rr = roundrobin:new(servers, true)
            local id = rr:find()

            local rr2 = roundrobin:new(servers, true)
            local id2 = rr2:find()
            ngx.log(ngx.INFO, "id: ", id, " id2: ", id2)
            ngx.say(id == id2)
        }
    }
--- request
GET /t
--- response_body
false
--- no_error_log
[error]



=== TEST 4: weight is "0"
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            math.randomseed(9975098)

            local roundrobin = require "resty.roundrobin"

            local servers = {
                ["server1"] = "0",
                ["server2"] = "1",
                ["server3"] = "0",
                ["server4"] = "0",
            }

            local rr = roundrobin:new(servers, true)
            local id = rr:find()

            ngx.say("id: ", id)
        }
    }
--- request
GET /t
--- response_body
id: server2
--- no_error_log
[error]
