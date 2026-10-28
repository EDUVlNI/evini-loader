"""Static-only inspection of VinGUI. Never imports, evaluates or runs reference code."""
import argparse,hashlib,json,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--output',type=Path);args=p.parse_args()
raw=args.source.read_bytes();source=raw.decode('utf-8');match=re.search(r'"LPH>([0-9A-FH]+)"',source)
report={'source_bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'executed':False,'payload_marker':bool(match)}
terms=['Spectate','spectate','AimViewer','CameraSubject','CameraType','MousePos','GetPlayers','UserId','DisplayName','CurrentCamera']
report['source_hits']={term:source.count(term) for term in terms}
if match:
    encoded=match.group(1);assert len(encoded)%2==0
    result=bytearray();repeat=None
    for i in range(0,len(encoded),2):
        pair=encoded[i:i+2]
        if pair[1]=='H':
            assert repeat is None;repeat=int(pair[0])
        else:
            result.extend(bytes([int(pair,16)])*(repeat if repeat is not None else 1));repeat=None
        assert len(result)<10_000_000
    assert repeat is None
    report['encoding']='hex pairs; nH repeats the next decoded byte n times'
    report['decoded_bytes']=len(result)
    report['decoded_sha256']=hashlib.sha256(result).hexdigest()
    report['payload_hits']={term:bytes(result).count(term.encode()) for term in terms}
    report['printable_runs']=[m.decode('ascii') for m in re.findall(rb'[\x20-\x7e]{8,}',result)][:25]
report['conclusion']='Encoded virtualized program; lexical absence does not establish feature absence. VM/opcodes were not executed.'
text=json.dumps(report,ensure_ascii=False,indent=2)
if args.output:args.output.write_text(text+'\n')
print(text)
