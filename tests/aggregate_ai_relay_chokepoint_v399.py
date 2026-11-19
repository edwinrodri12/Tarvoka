#!/usr/bin/env python3
"""TARVOKA v3.9.9: strict opt-in narrow-terrain screen holdout.

Four previously unused seeds: two double-bridge, two forest;
fog yes/no x starter 0/1. 16 original paired comparisons (baseline vs
screen), each mirrored exactly, total 64 played matches. Mirrored
replays must NOT be counted as independent conditions.
"""
import json
import pathlib
import sys

PREFIX="SCREEN399_RESULT "
SEEDS=(674,677,678,681)
SEED_TEMPLATE={674:2,677:1,678:2,681:1}
POLICIES=("baseline","screen")

def read(folder):
    observed={}
    for path in sorted(pathlib.Path(folder).rglob("*.log")):
        for line in path.read_text(encoding="utf-8",errors="replace").splitlines():
            p=line.find(PREFIX+"{")
            if p<0:
                continue
            row=json.loads(line[p+len(PREFIX):])
            key=(row["seed"],row["fog"],row["starter"])
            assert key not in observed and key[0] in SEEDS
            assert type(key[1]) is bool and key[2] in (0,1)
            assert row["version"]=="v3.9.9"
            assert row["template"]==SEED_TEMPLATE[row["seed"]]
            assert row["size"]=="40x30" and row["half_turn_cap"]==36
            assert row["official_opening"] is True
            assert row["screen_flag_default_off"] is True
            assert row["no_game_rule_changes"] is True
            assert row["original_cases_per_policy"]==1
            assert row["mirror_checks_per_policy"]==1
            assert row["exact_mirrors"] is True
            for policy in POLICIES:
                game=row[policy]
                assert game["winner"] in (-1,0,1)
                assert game["starter_wins"] is (game["winner"]==row["starter"])
                assert game["responder_wins"] is (game["winner"]==1-row["starter"])
                assert game["censored"] is (game["winner"]==-1)
                assert 0<game["half_turns"]<=36
                assert game["terminal"] in ("winner","phase_limit","idle_stalemate")
                assert (game["terminal"]=="winner") is (not game["censored"])
                assert all(game[v]>=0 for v in ("actions","attacks","purchases"))
                assert len(game["relay_scores"])==2
                assert len(game["first_relay_capture"])==2
                assert len(game["relay_capture_count"])==2
                assert len(game["first_city_capture"])==2
            diff=row["first_divergence"]
            assert type(diff["changed"]) is bool
            if diff["changed"]:
                assert diff["frame"]>0
                if not diff.get("trace_size_only",False):
                    assert diff["phase"]>=0
                    assert diff["baseline_decision"] is not None
                    assert diff["candidate_decision"] is not None
            else:
                assert diff["frame"]==-1
                assert row["baseline"]==row["screen"]
            observed[key]=row
    expected={(seed,fog,first)
              for seed in SEEDS for fog in (False,True) for first in (0,1)}
    assert set(observed)==expected,("missing pairs",sorted(expected-set(observed)))
    return [observed[k] for k in sorted(expected)]

def summarize(rows,policy):
    games=[r[policy] for r in rows]
    assert games
    return {
        "conditions":len(games),
        "first_wins":sum(g["starter_wins"] for g in games),
        "second_wins":sum(g["responder_wins"] for g in games),
        "censored":sum(g["censored"] for g in games),
        "half_turn_total":sum(g["half_turns"] for g in games),
        "half_turn_mean":sum(g["half_turns"] for g in games)/len(games),
        "attacks":sum(g["attacks"] for g in games),
        "purchases":sum(g["purchases"] for g in games),
        "relay_captures":sum(sum(g["relay_capture_count"]) for g in games),
        "first_starter_relay":sum(
            g["first_relay_capture"][r["starter"]]>=0 and (
                g["first_relay_capture"][1-r["starter"]]==-1 or
                g["first_relay_capture"][r["starter"]]<
                g["first_relay_capture"][1-r["starter"]])
            for r,g in zip(rows,games))
    }

def main(folder):
    rows=read(folder)
    changed=[r for r in rows if r["first_divergence"]["changed"]]
    result={
        "version":"v3.9.9",
        "status":"research_only_disable_by_default",
        "strategy":"observed visible-enemy bottleneck route interference defending already-garrisoned owned relays",
        "seeds":list(SEEDS),
        "genuinely_new_relative_to_prior_ai_trials":True,
        "templates":{str(s):SEED_TEMPLATE[s] for s in SEEDS},
        "size":"40x30",
        "fog":[False,True],
        "both_starters":True,
        "original_paired_conditions":16,
        "actual_played_with_mirrors":64,
        "mirrors_independent":False,
        "official_opening":True,
        "rules_changed":False,
        "default_flag_off":True,
        "by_policy":{p:summarize(rows,p) for p in POLICIES},
        "by_fog":{
            str(fog).lower():{p:summarize(
                [r for r in rows if r["fog"]==fog],p) for p in POLICIES}
            for fog in (False,True)
        },
        "by_template":{
            str(template):{p:summarize(
                [r for r in rows if r["template"]==template],p)
                for p in POLICIES} for template in (1,2)
        },
        "first_actions_changed":len(changed),
        "winner_or_censor_changed":sum(
            r["baseline"]["winner"]!=r["screen"]["winner"] for r in rows),
        "changed_by_fog":{
            str(fog).lower():sum(r["fog"]==fog for r in changed)
            for fog in (False,True)
        },
        "per_seed":{
            str(seed):{p:summarize(
                [r for r in rows if r["seed"]==seed],p)
                for p in POLICIES} for seed in SEEDS
        },
        "warn":[
            "The baseline is the official AI; previous v398 planner remains OFF in BOTH policies.",
            "The only candidate option is _ab_relay_screen_v399, OFF by default.",
            "A chokepoint is a known, impassable-sided corridor; speculation about hidden enemies is prohibited.",
            "Exact mirrored games verify parity and are not statistically independent observations.",
            "Outcomes on seeds in the same map category/initiative are correlated.",
            "Unresolved games at half-turn 36 remain censored, not fictitious draws.",
            "Decision changes do not imply improved balance or difficulty; require robust wins in later tests.",
            "The experiment modifies neither gameplay rules, money, unit stats, fog, save format, APK nor main."
        ]
    }
    out=pathlib.Path("reports")
    out.mkdir(exist_ok=True)
    (out/"ai_v399_relay_chokepoint_screen.json").write_text(
        json.dumps({"summary":result,"cases":rows},ensure_ascii=False,indent=2)+"\n",
        encoding="utf-8")
    md=[
        "# TARVOKA v3.9.9 — ¿Ayuda a la IA proteger los pasos estrechos?",
        "",
        "Nuevo planificador **opt-in OFF**. Comparación de la IA actual "
        "contra el bloqueo posicional de cuellos de botella realmente conocidos "
        "que protegen relés ya ocupados. Se comparan 16 condiciones originales "
        "(4 semillas nuevas × niebla sí/no × ambos iniciadores), con 64 "
        "partidas si se cuentan espejos; **espejos no son muestras nuevas**.",
        "",
        "| IA | Primero gana | Segundo gana | Censuradas | Medios turnos promedio |",
        "|---|---:|---:|---:|---:|"
    ]
    for p in POLICIES:
        stats=result["by_policy"][p]
        md.append(f"| {p} | {stats['first_wins']} | {stats['second_wins']} | "
                  f"{stats['censored']} | {stats['half_turn_mean']:.1f} |")
    md += ["","## Niebla","","| Niebla | IA | Primero | Segundo | Censuras |",
           "|---|---|---:|---:|---:|"]
    for fog in ("false","true"):
        for p in POLICIES:
            s=result["by_fog"][fog][p]
            md.append(f"| {fog} | {p} | {s['first_wins']} | "
                      f"{s['second_wins']} | {s['censored']} |")
    md += ["","## Tipo de terreno","","| Terreno | IA | Primero | Segundo | Censuras |",
           "|---|---|---:|---:|---:|"]
    for template in (1,2):
        for p in POLICIES:
            s=result["by_template"][str(template)][p]
            md.append(f"| {template} | {p} | {s['first_wins']} | "
                      f"{s['second_wins']} | {s['censored']} |")
    md += ["",
           f"En {result['first_actions_changed']}/16 pares ocurrió una "
           f"divergencia de acciones; en {result['winner_or_censor_changed']}/16 "
           "cambió el resultado o la censura.",
           "",
           "**No activar automáticamente:** necesita legalidad, simetría "
           "completa y mejora robusta con niebla, en puentes y en mapas sin "
           "pasos estrechos. Ninguna bonificación por orden de inicio.",
           ""]
    (out/"ai_v399_relay_chokepoint_screen.md").write_text(
        "\n".join(md),encoding="utf-8")
    print("SCREEN399_ALL "+json.dumps({k:v for k,v in result.items()
         if k!="per_seed"},ensure_ascii=False,separators=(",",":")))
    print("\n".join(md))
    print("PASS TARVOKA v399 aggregate: strict 16 paired independent outcomes plus 64 mirrored replays")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v399-logs")
