# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

$ENV{TEST_NGINX_CWD} = $pwd;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "/usr/local/lib/?.so;;";
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: find
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local resty_chash = require "resty.chash"

            local servers = {
                ["server1"] = 10,
                ["server2"] = 2,
                ["server3"] = 1,
            }

            local chash = resty_chash:new(servers)

            local res = {}
            for i = 1, 100 * 1000 do
                local id = chash:find(i)

                if res[id] then
                    res[id] = res[id] + 1
                else
                    res[id] = 1
                end
            end

            for id, num in pairs(res) do
                ngx.say(id, ": ", num)
            end

            ngx.say("points number: ", chash.npoints)
        }
    }
--- request
GET /t
--- response_body
server2: 16114
server3: 8298
server1: 75588
points number: 2080
--- no_error_log
[error]
