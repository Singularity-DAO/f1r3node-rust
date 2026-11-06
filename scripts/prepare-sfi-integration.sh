#!/usr/bin/env bash
set -euo pipefail

command -v jq > /dev/null || { printf 'jq is required.\n' >&2; exit 1; }

if [ "$#" -ne 2 ]; then
	printf 'Usage: %s <system-integration-dir> <venv-dir>\n' "$0" >&2
	exit 2
fi
harness=$(cd "$1" && pwd -P)
venv=$(cd "$2" && pwd -P)
lock_hash=$(sha256sum "$harness/poetry.lock" | cut -d ' ' -f 1)
if [ "$lock_hash" != a686d00e8c72145dd70b2809a08bd97aed5d22d5d0c0cc4a56de6fa52ee3086d ]; then
	printf 'Expected the dependency lock from system-integration 61ae9d14c4b8b8881fc0a82a2b6eac3fcbe5a797.\n' >&2
	exit 1
fi
metadata=("$venv"/lib/python*/site-packages/pyf1r3fly-*.dist-info/direct_url.json)
if [ "${#metadata[@]}" -ne 1 ] || [ ! -f "${metadata[0]}" ] ||
	! jq -e '.vcs_info.commit_id == "34ff0419456ffce6866a04d9d92d55d67e76e09b"' "${metadata[0]}" > /dev/null; then
	printf 'Expected pyf1r3fly 34ff0419456ffce6866a04d9d92d55d67e76e09b.\n' >&2
	exit 1
fi
fixture="$harness/integration-tests/resources/wallets/bond.rho"
genesis="$harness/integration-tests/test/tests/shared/test_genesis_ceremony.py"
web_api="$harness/integration-tests/test/tests/shared/test_web_api.py"
queries="$harness/integration-tests/test/tests/shared/test_query_endpoints.py"
lifecycle="$harness/integration-tests/test/tests/custom/test_validator_lifecycle.py"
websocket="$harness/integration-tests/test/tests/custom/test_websocket.py"
contracts="$harness/integration-tests/test/tests/shared/test_contract_lifecycle.py"
clients=("$venv"/lib/python*/site-packages/f1r3fly/pos.py)
if [ "${#clients[@]}" -ne 1 ] || [ ! -f "${clients[0]}" ] || [ ! -f "$fixture" ] || [ ! -f "$genesis" ] || [ ! -f "$web_api" ] || [ ! -f "$queries" ] || [ ! -f "$lifecycle" ] || [ ! -f "$websocket" ] || [ ! -f "$contracts" ]; then
	printf 'Expected one installed f1r3fly client and the pinned integration fixtures.\n' >&2
	exit 1
fi
client=${clients[0]}
fixture_hash=$(sha256sum "$fixture" | cut -d ' ' -f 1)
case "$fixture_hash" in
	fd07ecb389e752c6d5ce9144ff2fe5187f4047d5c00a75ee7e8c52e2c846e573 | f42d10e4beaa6065992a5c0de2b51e7464c2446aa4c4331dbdc5d4e5a2540ed1) ;;
	*) printf 'Unexpected bonding fixture content; no files changed.\n' >&2; exit 1 ;;
esac
genesis_hash=$(sha256sum "$genesis" | cut -d ' ' -f 1)
case "$genesis_hash" in
	84f6edf7939a41891e9919e67d28dc08aa34555c5cc30dc85c7fbe36f7ae9037 | 667bd5c63f2e46d4cae5018e1d5c5c94e26e250c513ba05353f5bb7866f31da8) ;;
	*) printf 'Unexpected genesis fixture content; no files changed.\n' >&2; exit 1 ;;
esac
web_api_hash=$(sha256sum "$web_api" | cut -d ' ' -f 1)
case "$web_api_hash" in
	64dd7fd78af08142ccc097c5be00fdd773dc36f88d76ccdfb78e4ae8f0ce9fe3 | d13a7a454fcf3f4566aaac6b934d336c1442e689d7d90a5b782826a02011fc86) ;;
	*) printf 'Unexpected web API fixture content; no files changed.\n' >&2; exit 1 ;;
esac
queries_hash=$(sha256sum "$queries" | cut -d ' ' -f 1)
case "$queries_hash" in
	3d27de4182a438f323808b24117b59249413725187b34826cad44e89cc2a19c3 | f194ea37f4751508c0182581b76002bc64c7985b707abfc8daa49e7d20c7208f) ;;
	*) printf 'Unexpected query fixture content; no files changed.\n' >&2; exit 1 ;;
esac
lifecycle_hash=$(sha256sum "$lifecycle" | cut -d ' ' -f 1)
case "$lifecycle_hash" in
	6e6b9500a514d65a0c4ced11ca1ea59d7523a39193a0a16c3347bc9b36c4417b | 6d0b5ce542414a05eda40b4a200941fb2ffa8790eaea7c7186a0afd0e92e1abe) ;;
	*) printf 'Unexpected validator lifecycle fixture content; no files changed.\n' >&2; exit 1 ;;
esac
websocket_hash=$(sha256sum "$websocket" | cut -d ' ' -f 1)
case "$websocket_hash" in
	73a2a7b8ed5f75b2154de3b9f85166b01f722ec0ab7ffbddeb62c2c1e252b062 | b5a263cf4261ab7375a67ded14d18501da8488a4bb3176f3889e871a35755fa1) ;;
	*) printf 'Unexpected WebSocket fixture content; no files changed.\n' >&2; exit 1 ;;
esac
contracts_hash=$(sha256sum "$contracts" | cut -d ' ' -f 1)
case "$contracts_hash" in
	65b674b2d2ca68acfa12026e3e6339b9d2fa83c4c943b6e0efff1ee0e560aacd | ad2abf071f7d2d4c5d8b32afbb972826892f26987838707b05d827dcf73e974f) ;;
	*) printf 'Unexpected contract lifecycle fixture content; no files changed.\n' >&2; exit 1 ;;
esac
original_fixture='@PoS!("bond", *deployerId, %AMOUNT, *retCh)'
updated_fixture='@PoS!("bond", *deployerId, %AMOUNTn, *retCh)'
original_client='@PoS!("bond", *deployerId, $amount, *retCh)'
updated_client='@PoS!("bond", *deployerId, ${amount}n, *retCh)'
for index in 0 1; do
	if [ "$index" -eq 0 ]; then
		file=$fixture original=$original_fixture updated=$updated_fixture
	else
		file=$client original=$original_client updated=$updated_client
	fi
	count=$(grep -Fc "$original" "$file" || true)
	patched=$(grep -Fc "$updated" "$file" || true)
	if ! { [ "$count" -eq 1 ] && [ "$patched" -eq 0 ]; } &&
		! { [ "$count" -eq 0 ] && [ "$patched" -eq 1 ]; }; then
		printf 'Unexpected bonding template in %s; no files changed.\n' "$file" >&2
		exit 1
	fi
done
sed -i 's/@PoS!("bond", \*deployerId, %AMOUNT, \*retCh)/@PoS!("bond", *deployerId, %AMOUNTn, *retCh)/' "$fixture"
sed -i 's/@PoS!("bond", \*deployerId, \$amount, \*retCh)/@PoS!("bond", *deployerId, ${amount}n, *retCh)/' "$client"
sed -i 's/blocks = node.get_blocks(100)/blocks = node._external_client().get_blocks_by_heights(0, 0)/; s/could not find block #0 in get_blocks(100)/could not find block #0 in get_blocks_by_heights(0, 0)/; s/fetching deep enough to find block #0/querying block height 0/' "$genesis"
sed -i 's/assert bond\["stake"\] == expect\["stakes"\]\[validator\]/assert bond["stake"] == str(expect["stakes"][validator])/' "$web_api"
sed -i 's/assert v\["stake"\] == expected_stakes\[v\["publicKey"\]\]/assert v["stake"] == str(expected_stakes[v["publicKey"]])/; s/assert result\["totalStake"\] == expected_total/assert result["totalStake"] == str(expected_total)/; s/assert isinstance(result\["stake"\], int) and result\["stake"\] > 0/assert result["stake"] == str(next(stake for identity, stake in shared_shard.config.bonds if identity.public_hex == pubkey))/; s/totalStake=%d/totalStake=%s/; s/bonded, stake=%d/bonded, stake=%s/' "$queries"
if [ "$lifecycle_hash" = 6e6b9500a514d65a0c4ced11ca1ea59d7523a39193a0a16c3347bc9b36c4417b ]; then
	lifecycle_tmp=$(mktemp "${lifecycle}.XXXXXX")
	trap 'rm -f "$lifecycle_tmp"' EXIT
	awk '
		$0 == "    return {v[\"publicKey\"]: v[\"stake\"] for v in resp[\"validators\"]}" {
			print "    for validator in resp[\"validators\"]:"
			print "        stake = validator[\"stake\"]"
			print "        assert ("
			print "            isinstance(stake, str)"
			print "            and stake.isascii()"
			print "            and stake.isdecimal()"
			print "            and str(int(stake)) == stake"
			print "        ), f\"expected a canonical decimal-string stake, got {stake!r}\""
			print "    return {v[\"publicKey\"]: int(v[\"stake\"]) for v in resp[\"validators\"]}"
			next
		}
		{ print }
	' "$lifecycle" > "$lifecycle_tmp"
	test "$(sha256sum "$lifecycle_tmp" | cut -d ' ' -f 1)" = 6d0b5ce542414a05eda40b4a200941fb2ffa8790eaea7c7186a0afd0e92e1abe
	chmod --reference="$lifecycle" "$lifecycle_tmp"
	mv -- "$lifecycle_tmp" "$lifecycle"
	trap - EXIT
fi
if [ "$websocket_hash" = 73a2a7b8ed5f75b2154de3b9f85166b01f722ec0ab7ffbddeb62c2c1e252b062 ]; then
	websocket_tmp=$(mktemp "${websocket}.XXXXXX")
	trap 'rm -f "$websocket_tmp"' EXIT
	awk '
		$0 == "from ...infra.types import NodeRole" { next }
		$0 == "        self.ro_errors: List[str] = []" {
			print
			print "        self.validator: Node | None = None"
			next
		}
		$0 == "        v1 = shard.node(\"validator1\")" {
			print
			print "        result.validator = v1"
			next
		}
		$0 == "    v1_handle = None" {
			print "    v1 = ws_shard.validator"
			print "    assert v1 is not None, \"WebSocket shard validator was not initialized\""
			skip = 1
			next
		}
		skip && $0 == "    v1 = Node(handle=v1_handle, role=NodeRole.VALIDATOR)" { skip = 0; next }
		!skip { print }
	' "$websocket" > "$websocket_tmp"
	test "$(sha256sum "$websocket_tmp" | cut -d ' ' -f 1)" = b5a263cf4261ab7375a67ded14d18501da8488a4bb3176f3889e871a35755fa1
	chmod --reference="$websocket" "$websocket_tmp"
	mv -- "$websocket_tmp" "$websocket"
	trap - EXIT
fi
if [ "$contracts_hash" = 65b674b2d2ca68acfa12026e3e6339b9d2fa83c4c943b6e0efff1ee0e560aacd ]; then
	contracts_tmp=$(mktemp "${contracts}.XXXXXX")
	trap 'rm -f "$contracts_tmp"' EXIT
	awk '
		$0 == "    wait_for_finalized(ro, lock1_num + 1, lfb_timeout)" {
			print "    lfb_hash = common_finalized_anchor([validators[0], ro], lfb_timeout)"
			skip = 1; next
		}
		$0 == "    wait_for_finalized(ro, lock2_num + 1, lfb_timeout)" {
			print "    lfb_hash = common_finalized_anchor([validators[1], ro], lfb_timeout)"
			skip = 1; next
		}
		skip { skip = 0; next }
		{ print }
	' "$contracts" > "$contracts_tmp"
	test "$(sha256sum "$contracts_tmp" | cut -d ' ' -f 1)" = ad2abf071f7d2d4c5d8b32afbb972826892f26987838707b05d827dcf73e974f
	chmod --reference="$contracts" "$contracts_tmp"
	mv -- "$contracts_tmp" "$contracts"
	trap - EXIT
fi
printf 'Prepared BigInt inputs, exact stake fixtures, genesis lookup, shard-scoped WebSockets, and finalized contract read anchors in %s.\n' "$harness"
