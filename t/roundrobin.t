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

                ngx.say("id: ", id)
            end
        }
    }
--- request
GET /t
--- response_body
gcd: 2
id: server1
id: server1
id: server1
id: server2
id: server1
id: server2
id: server3
id: server1
id: server1
id: server1
id: server2
id: server1
id: server2
id: server3
--- no_error_log
[error]



=== TEST 2: find count
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local roundrobin = require "resty.roundrobin"

            local servers = {
                ["server1"] = 6,
                ["server2"] = 4,
                ["server3"] = 2,
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

            for id, num in pairs(res) do
                ngx.say(id, ": ", num)
            end
        }
    }
--- request
GET /t
--- response_body
server1: 50001
server3: 16666
server2: 33333
--- no_error_log
[error]
