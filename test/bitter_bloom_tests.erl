-module(bitter_bloom_tests).
-author('mbranton@emberfinancial.com').


-include_lib("bitter_bloom/include/bitter_bloom.hrl").
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-compile(export_all).

start() -> ok.
stop(_) -> ok.


%% Proper based testing

prop_empty_matches() ->
	{ok, Bloom} = bitter_bloom:new(100, 0.001),
	?FORALL(B, binary(),
			false =:= bitter_bloom:contains(Bloom, B)).

prop_probabilistic_matching(Bloom) ->
	?FORALL(B, binary(),
			begin
				{ok, Bloom2} = bitter_bloom:insert(Bloom, B),
				true =:= bitter_bloom:contains(Bloom2, B)
			end).

prop_creation() ->
	?FORALL(N, tuple([integer(), real()]),
			begin
				{NumElements, FalsePositiveRate} = N,
				{ok, Bloom} = bitter_bloom:new(NumElements, FalsePositiveRate),
				prop_probabilistic_matching(Bloom)
			end).

prop_negative(Bloom) ->
	?FORALL(B, binary(), false =:= bitter_bloom:contains(Bloom, B)).

check_empty() ->
	?assertEqual(true, proper:quickcheck(prop_empty_matches(), [{to_file, user}])).

check_matching() ->
	{ok, Bloom} =  bitter_bloom:new(1000, 0.001),
	?assertEqual(true, proper:quickcheck(prop_probabilistic_matching(Bloom), [{to_file, user}])).

random_sizing() ->
	?assertEqual(true, proper:quickcheck(prop_creation(), [{to_file, user}])).

negative_match() ->
	{ok, Bloom} = bitter_bloom:new(100, 0.001),
	{ok, Bloom2} = bitter_bloom:insert(Bloom, <<"Justsomerandomsampledata">>),
	?assertEqual(true, proper:quickcheck(prop_negative(Bloom2), [{to_file, user}])).

quick_bloom_test_() ->
	{foreach,
	 fun start/0,
	 fun stop/1,
	 [
	  {"Empty never matches", fun check_empty/0},
	  {"matching checking", fun check_matching/0},
	  {"Random sizing", fun random_sizing/0},
	  {"Negatives", fun negative_match/0}
	 ]
	}.
