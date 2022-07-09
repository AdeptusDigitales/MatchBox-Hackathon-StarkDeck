from starkware.crypto.signature.signature import (
    pedersen_hash, private_to_stark_key, sign)

private_key = 321
message_hash = pedersen_hash(16491467447720217910)
public_key = private_to_stark_key(private_key)
signature = sign(
    msg_hash=message_hash, priv_key=private_key)

print(f'Public key: {public_key}')
print(f'Signature: {signature}')
print(f'Message Hash: {message_hash}')