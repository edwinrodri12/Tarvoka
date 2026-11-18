#!/usr/bin/env python3
"""Strict real-match v3.9.3 double-bridge forensic aggregation.

8 deterministic type-2 seeds (2 reference, 6 unseen) x fog on/off x
two starters, plus one exact mirror for each official game. Mirrors
are deterministic checks, never independent outcome samples.
"""
import json
import pathlib
import sys

PREFIX="BRIDGE393_RESULT "
SEEDS=(634,638,642,646,650,654,658,662)
REFERENCE={634,638}

def load(folder):
    found={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            p=line.find(PREFIX+"{")
            if p<0:continue
            r=json.loads(line[p+len(PREFIX):])
            key=(r["seed"],r["fog"],r["first"])
            assert key not in found and key[0] in SEEDS,("duplicate/unexpected",key)
            assert type(r["fog"]) is bool and r["first"] in (0,1)
            assert r["version"]=="v3.9.3" and r["template"]==2
            assert r["size"]=="40x30" and r["bridge_rows"]==[8,21]
            assert r["previously_observed_seed"] is (r["seed"] in REFERENCE)
            assert r["official_opening_only"] is True
            assert r["production_rules_changed"] is False
            assert r["observation_half_turns"]==40
            assert r["independent_original_samples"]==1 and r["mirror_replays"]==1
            g=r["game"]
            assert g["first"]==r["first"] and g["winner"] in (-1,0,1)
            assert g["censored"] is (g["winner"]==-1)
            assert g["winner_first"] is (g["winner"]==r["first"])
            assert g["winner_responder"] is (g["winner"]==1-r["first"])
            assert g["terminal"] in ("winner","idle_stalemate","phase_limit")
            assert (g["terminal"]=="winner") is (g["winner"]>=0)
            assert g["opening_starter_orders"]==3 and g["mirror_exact"] is True
            assert 0<g["half_turns"]<=40
            assert g["actions"]>=0 and g["attacks"]>=0 and g["purchases"]>=0
            assert g["resupplies"]>=0
            l=g["ledger"]
            assert l["completed_phases"]==g["half_turns"]
            assert len(l["final_scores"])==2 and l["final_scores"]==g["end_relay_scores"]
            assert len(l["final_relay_holdings"])==2 and sum(l["final_relay_holdings"])<=4
            assert l["orders_first_12_phases"][0]==3
            assert l["orders_first_12_phases"][1] in (7,8)
            assert len(l["first_relay_phase"])==2 and len(l["first_city_phase"])==2
            assert l["relay_capture_count"]==[
                sum(e["capturing_side"]==side for e in l["relay_captures"])
                for side in (0,1)]
            assert l["city_capture_count"]==[
                sum(e["capturing_side"]==side for e in l["city_captures"])
                for side in (0,1)]
            previous=[0,0]
            for snap in l["first_12_snapshots"]:
                phase=snap["phase"]
                if phase%2==1:
                    expected=[previous[i]+snap["owners"][i] for i in (0,1)]
                    assert snap["scores"]==expected
                else:
                    assert snap["scores"]==previous
                assert 0<=sum(snap["owners"])<=4
                previous=snap["scores"]
            found[key]=r
    expected={(seed,fog,first) for seed in SEEDS for fog in (False,True)
              for first in (0,1)}
    assert set(found)==expected and len(found)==32,(
        "incomplete genuine cases",len(found),sorted(expected-set(found)))
    return [found[k] for k in sorted(expected)]

def stats(rows):
    assert rows
    games=[x["game"] for x in rows]
    return {
        "original_samples":len(rows),
        "decisive":sum(not x["censored"] for x in games),
        "censored":sum(x["censored"] for x in games),
        "starter_wins":sum(x["winner_first"] for x in games),
        "responder_wins":sum(x["winner_responder"] for x in games),
        "half_turn_total":sum(x["half_turns"] for x in games),
        "mean_half_turns":sum(x["half_turns"] for x in games)/len(games),
        "total_relay_captures":sum(sum(x["ledger"]["relay_capture_count"]) for x in games),
        "total_city_captures":sum(sum(x["ledger"]["city_capture_count"]) for x in games),
        "starter_first_relay_captures":sum(x["ledger"]["first_relay_phase"][r["first"]]>=0 for r,x in zip(rows,games)),
        "responder_first_relay_captures":sum(x["ledger"]["first_relay_phase"][1-r["first"]]>=0 for r,x in zip(rows,games)),
        "starter_city_captures":sum(x["ledger"]["city_capture_count"][r["first"]] for r,x in zip(rows,games)),
        "responder_city_captures":sum(x["ledger"]["city_capture_count"][1-r["first"]] for r,x in zip(rows,games))
    }

def main(folder):
    rows=load(folder)
    initial=[r for r in rows if r["seed"] in REFERENCE]
    unseen=[r for r in rows if r["seed"] not in REFERENCE]
    assert len(initial)==8 and len(unseen)==24
    report={
        "version":"v3.9.3","status":"diagnostic_only",
        "hypothesis":"Do the two bridge crossings consistently favor the responding side under official opening policy?",
        "map_type":2,
        "map_description":"Cuenca con dos puentes",
        "seeds":list(SEEDS),
        "out_of_sample_seeds":[s for s in SEEDS if s not in REFERENCE],
        "previously_studied_seeds":sorted(REFERENCE),
        "genuine_original_conditions":32,
        "mirror_replays":32,
        "actual_games":64,
        "mirror_replays_are_not_independent":True,
        "rules_unchanged":True,
        "policy":"starter 3 orders; responder 7 or 8, no artificial cap",
        "horizon_half_turns":40,
        "all":stats(rows),
        "previously_studied":stats(initial),
        "new_seed_only":stats(unseen),
        "by_fog":{
            str(fog).lower():stats([r for r in rows if r["fog"]==fog])
            for fog in (False,True)
        },
        "by_seed":{str(seed):stats([r for r in rows if r["seed"]==seed]) for seed in SEEDS},
        "warnings":[
            "No scoring, economy, AI, opening, movement, fog, terrain or APK changes.",
            "Previous 634/638 seed results are not out-of-sample; 642..662 are reserved untouched holdouts.",
            "Starter identities on the same map/fog are correlated; do not claim independently randomized matches.",
            "Reflected mirrors audit exact action/state parity and never increase outcome sample size.",
            "The result characterizes this single AI and double-bridge map, not all faction or human outcomes.",
            "Natural non-victory at 40 half turns is censored, never labeled a draw."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(parents=True,exist_ok=True)
    (out/"ai_v393_double_bridge_forensic.json").write_text(
        json.dumps({"summary":report,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.3 — Forense del mapa de dos puentes",
        "",
        "**Apertura OFICIAL, IA actual sin opciones experimentales**, 40×30. "
        "32 condiciones reales y 32 reflejos exactos: 64 partidas, "
        "sin contar el reflejo como una nueva muestra.",
        "",
        "| Muestra | Casos | Iniciador gana | Respondedor gana | Censuradas | Media medios turnos |",
        "|---|---:|---:|---:|---:|---:|"
    ]
    for key,label in [("all","Total"),("previously_studied","Semillas conocidas 634/638"),
                      ("new_seed_only","Seis semillas NUEVAS 642–662")]:
        a=report[key]
        md.append(f"| {label} | {a['original_samples']} | {a['starter_wins']} | "
                  f"{a['responder_wins']} | {a['censored']} | {a['mean_half_turns']:.1f} |")
    md += ["","## Por niebla","","| Niebla | Casos | Iniciador gana | Respondedor gana | Censuradas |",
           "|---|---:|---:|---:|---:|"]
    for fog in ("false","true"):
        a=report["by_fog"][fog]
        md.append(f"| {fog} | {a['original_samples']} | {a['starter_wins']} | "
                  f"{a['responder_wins']} | {a['censored']} |")
    md += ["", "## Captura objetiva y dinámica", ""]
    a=report["new_seed_only"]
    md.append(f"En semillas nuevas: {a['total_relay_captures']} capturas reales "
              f"de relés y {a['total_city_captures']} capturas de ciudades. "
              f"{a['starter_first_relay_captures']} partidas registraron captura "
              f"de relé por el iniciador; {a['responder_first_relay_captures']} "
              f"por el respondedor. Capturas de ciudades: iniciador "
              f"{a['starter_city_captures']}, respondedor {a['responder_city_captures']}.")
    md += [
        "",
        "El archivo JSON conserva cada evento de captura, casilla, media ronda, "
        "propietario de relés, marcador y número de órdenes por fase. "
        "La contabilidad del relé se audita en cada final de medio turno.",
        "",
        "**Este informe es descriptivo. No aprueba bonus de dinero, órdenes "
        "gratuitas ni cambios de reglas de turno.**",
        ""
    ]
    (out/"ai_v393_double_bridge_forensic.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("BRIDGE393_ALL "+json.dumps(report,separators=(",",":"),ensure_ascii=False))
    print("\n".join(md))
    print("PASS TARVOKA v393 aggregate: 32 official bridge-match conditions and 32 exact mirrored replays")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v393-logs")
