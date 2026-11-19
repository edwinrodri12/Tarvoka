#!/usr/bin/env python3
"""v4.0.2 exact opening forensics of two asymmetric AI configurations.

8 untouched seeds 698-705, both fog states, both first-player colors,
both candidate side assignments = 64 genuine opening trials + 64
faction-swapped exact mirrors. Only 8 completed half turns are observed.
This is a diagnostic audit, NOT a gameplay win-rate experiment.
"""
import json
import pathlib
import sys

PREFIX="OPEN402_RESULT "
SEEDS=tuple(range(698,706))
EXPECTED={(seed,fog,first,cand) for seed in SEEDS
          for fog in (False,True) for first in (0,1) for cand in (0,1)}

def load(folder):
    cases={}
    for log in sorted(pathlib.Path(folder).rglob("*.log")):
        for raw in log.read_text(encoding="utf-8",errors="replace").splitlines():
            start=raw.find(PREFIX+"{")
            if start<0:
                continue
            row=json.loads(raw[start+len(PREFIX):])
            key=(row["seed"],row["fog"],row["first"],row["candidate_faction"])
            assert key in EXPECTED and key not in cases,("invalid / duplicate",key)
            assert row["version"]=="v4.0.2"
            assert row["template"]==row["seed"]%4
            assert type(row["fog"]) is bool
            assert row["candidate_started"] is (row["candidate_faction"]==row["first"])
            assert row["horizon_half_turns"]==8
            for fld in (
                "official_opening",
                "candidate_policy_only_for_one_side",
                "exact_mirror_with_policy_swapped",
                "no_gameplay_change"
            ):
                assert row[fld] is True
            assert row["original_games"]==1 and row["mirror_games"]==1
            a=row["opening"]
            assert 0<a["completed_end_turns"]<=8
            assert len(a["phases"])==a["completed_end_turns"]
            assert a["candidate_started"] is row["candidate_started"]
            assert a["winner"] in (-1,0,1)
            assert a["terminal"] in ("winner","phase_limit","idle_stalemate")
            assert a["first_response_order_count"]>=0
            assert len(a["first_three_orders"])==3
            assert len(a["first_response_orders"])==a["first_response_order_count"]
            assert len(a["first_response_orders"])<=50
            assert a["phases"][0]["orders_count"]==3
            for phase_idx,phase in enumerate(a["phases"]):
                assert phase["phase"]==phase_idx
                side=(row["first"] if phase_idx%2==0 else 1-row["first"])
                assert phase["side"]==side
                assert phase["who"]==(
                    "candidate" if row["candidate_faction"]==side
                    else "official")
                assert phase["orders_count"]>=0
                assert phase["purchases"]>=0 and phase["spent"]>=0
                assert phase["moves"]>=0 and phase["attacks"]>=0
                assert phase["resupplies"]>=0
                assert sum(phase[k] for k in (
                    "moves","attacks","purchases","resupplies"))==phase["orders_count"]
                for key2 in ("before","after"):
                    snap=phase[key2]
                    assert all(snap[k]>=0 for k in (
                        "credits","owned_cities","income_if_next_turn",
                        "owned_relays","relay_signal","living_units"))
                assert phase["city_change"]==(
                    phase["after"]["owned_cities"]-
                    phase["before"]["owned_cities"])
                assert phase["relay_change"]==(
                    phase["after"]["owned_relays"]-
                    phase["before"]["owned_relays"])
            assert a["first_three_orders"]==a["phases"][0]["orders"]
            assert a["first_response_orders"]==a["phases"][1]["orders"]
            assert a["candidate_final"]["credits"]>=0
            assert a["official_final"]["credits"]>=0
            cases[key]=row
    assert set(cases)==EXPECTED,(
        "missing",sorted(EXPECTED-set(cases)),
        "unexpected",sorted(set(cases)-EXPECTED))
    return [cases[k] for k in sorted(EXPECTED)]

def role(rows,who,phase_limit):
    records=[]
    for r in rows:
        for p in r["opening"]["phases"]:
            if p["phase"]>=phase_limit or p["who"]!=who:
                continue
            records.append(p)
    return {
        "phase_records":len(records),
        "orders":sum(p["orders_count"] for p in records),
        "moves":sum(p["moves"] for p in records),
        "purchases":sum(p["purchases"] for p in records),
        "total_spent_on_recruitment":sum(p["spent"] for p in records),
        "attacks":sum(p["attacks"] for p in records),
        "resupply_orders":sum(p["resupplies"] for p in records),
        "city_ownership_changes":sum(p["city_change"] for p in records),
        "relay_ownership_changes":sum(p["relay_change"] for p in records),
        "sum_income_potential_on_last_own_turn":sum(
            max([p["after"]["income_if_next_turn"] for p in r["opening"]["phases"]
                 if p["phase"]<phase_limit and p["who"]==who] or [0])
            for r in rows)
    }

def round_state(rows,who,phase_limit):
    result=[]
    for r in rows:
        phases=[p for p in r["opening"]["phases"]
                if p["phase"]<phase_limit and p["who"]==who]
        if not phases:
            continue
        result.append(phases[-1]["after"])
    return {
        "samples":len(result),
        "credits_total":sum(p["credits"] for p in result),
        "cities_total":sum(p["owned_cities"] for p in result),
        "future_income_total":sum(p["income_if_next_turn"] for p in result),
        "relays_total":sum(p["owned_relays"] for p in result),
        "signal_total":sum(p["relay_signal"] for p in result),
        "units_total":sum(p["living_units"] for p in result)
    }

def by_group(rows):
    return {
        "original_trials":len(rows),
        "candidate_first":sum(r["candidate_started"] for r in rows),
        "candidate_second":sum(not r["candidate_started"] for r in rows),
        "candidate_first_two_rounds":role(rows,"candidate",4),
        "official_first_two_rounds":role(rows,"official",4),
        "candidate_after_two_rounds":round_state(rows,"candidate",4),
        "official_after_two_rounds":round_state(rows,"official",4),
        "candidate_first_four_rounds":role(rows,"candidate",8),
        "official_first_four_rounds":role(rows,"official",8),
        "candidate_after_four_rounds":round_state(rows,"candidate",8),
        "official_after_four_rounds":round_state(rows,"official",8)
    }

def main(folder):
    cases=load(folder)
    pairs=[]
    for seed in SEEDS:
        for fog in (False,True):
            for first in (0,1):
                starter=next(r for r in cases if (
                    r["seed"],r["fog"],r["first"],r["candidate_faction"])==
                    (seed,fog,first,first))
                responder=next(r for r in cases if (
                    r["seed"],r["fog"],r["first"],r["candidate_faction"])==
                    (seed,fog,first,1-first))
                a=starter["opening"]
                b=responder["opening"]
                start_diff=a["first_three_orders"]!=b["first_three_orders"]
                reply_diff=a["first_response_orders"]!=b["first_response_orders"]
                pairs.append({
                    "seed":seed,"fog":fog,"first":first,
                    "first_three_actions_different":start_diff,
                    "responder_first_response_different":reply_diff,
                    "candidate_first_three":a["first_three_orders"],
                    "official_first_three":b["first_three_orders"],
                    "responder_after_candidate_opening":a["first_response_orders"],
                    "candidate_after_official_opening":b["first_response_orders"],
                    "candidate_own_phase0_purchases":a["phases"][0]["purchases"],
                    "official_own_phase0_purchases":b["phases"][0]["purchases"],
                    "candidate_own_phase0_moves":a["phases"][0]["moves"],
                    "official_own_phase0_moves":b["phases"][0]["moves"],
                    "candidate_second_phase1_purchases":b["phases"][1]["purchases"],
                    "official_second_phase1_purchases":a["phases"][1]["purchases"]
                })
    assert len(pairs)==32
    summary={
        "version":"v4.0.2",
        "status":"diagnostic_opening_trace_not_a_new_AI_strength_claim",
        "reference_head_to_head":"44471224226",
        "head_to_head_candidate_wins_original":28,
        "head_to_head_official_wins_original":36,
        "seeds":list(SEEDS),
        "seeds_not_used_in_v401":True,
        "map_templates":[0,1,2,3],
        "fog":[False,True],
        "original_policy_assignment_trials":64,
        "truly_paired_first_player_cases":32,
        "actual_games_including_mirrors":128,
        "mirror_games_counted_as_independent":False,
        "half_turns_observed_per_match_at_most":8,
        "all_game_rules_unchanged":True,
        "policy_assigned_only_to_one_faction":True,
        "overall":by_group(cases),
        "when_candidate_starts":by_group([r for r in cases if r["candidate_started"]]),
        "when_candidate_responds":by_group([r for r in cases if not r["candidate_started"]]),
        "by_fog":{
            str(fog).lower():by_group([r for r in cases if r["fog"]==fog])
            for fog in (False,True)
        },
        "by_template":{
            str(t):by_group([r for r in cases if r["template"]==t])
            for t in range(4)
        },
        "starter_action_divergences":sum(p["first_three_actions_different"] for p in pairs),
        "response_action_divergences":sum(p["responder_first_response_different"] for p in pairs),
        "pairs":pairs,
        "notes":[
            "This deliberately records 8 early half-turns, so terminal results are likely censored and cannot be treated as the win rate.",
            "The head-to-head v401 provided actual 36-halfturn win rates; this v402 looks for causes in early economic and strategic actions.",
            "Candidate and official are alternated as starter and as faction on the same observed map/seed.",
            "The mirrored counterpart changes faction label and swaps which side owns the policy; it is an exact parity check, not a new sample.",
            "Opening orders must still be exactly 3. All purchases pay normal costs.",
            "This script observes both treasuries to AUDIT after games; the AI itself still sees only Visibility.observed_state and never reads private opponent funds.",
            "Income_if_next_turn is a projected rate of EXISTING owned cities, never extra credits injected into the game.",
            "No balance bonus, no extra cash, no change to combat or fog, no edits to Android or production code."
        ]
    }
    folder_out=pathlib.Path("reports")
    folder_out.mkdir(parents=True,exist_ok=True)
    (folder_out/"ai_v402_opening_forensics.json").write_text(
        json.dumps({"summary":summary,"trials":cases},
                   ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    c=summary["when_candidate_starts"]["candidate_first_two_rounds"]
    o=summary["when_candidate_starts"]["official_first_two_rounds"]
    markdown=[
        "# TARVOKA v4.0.2 — Auditoría de las primeras decisiones económicas",
        "",
        "Diagnóstico adicional después de [v401](https://github.com/edwinrodri12/Tarvoka/actions/runs/44471224226), "
        "donde v400 solo ganó 8/32 iniciando y 28/64 en total. "
        "NO es una nueva IA ni una muestra de victorias: registra solo "
        "ocho medios turnos iniciales de cada partida.",
        "",
        "**64 partidas originales de 8 semillas nuevas**, con sus 64 espejos; "
        "32 pares comparten mapa y primer jugador pero intercambian qué "
        "bando controla la política económica.",
        "",
        f"- Primeras 3 órdenes del iniciador diferentes entre políticas: "
        f"**{summary['starter_action_divergences']}/32**.",
        f"- Primera respuesta del rival diferente entre asignaciones: "
        f"**{summary['response_action_divergences']}/32**.",
        "",
        "## Costos del primer ciclo de apertura (v400 comienza)",
        "",
        f"- Turnos de candidato antes de medio turno 4: {c['phase_records']}; "
        f"compras {c['purchases']}, movimientos {c['moves']}, "
        f"costo de compras {c['total_spent_on_recruitment']}.",
        f"- Turnos del oponente: {o['phase_records']}; "
        f"compras {o['purchases']}, movimientos {o['moves']}, "
        f"costo de compras {o['total_spent_on_recruitment']}.",
        "",
        "## Datos para elegir la siguiente mejora",
        "",
        "El informe JSON detalla, por semilla, niebla y bando: órdenes reales, "
        "producción, gastos, control urbano, ingresos futuros proyectados, "
        "relés, marcadores y unidades supervivientes. También compara "
        "directamente las primeras tres órdenes y la respuesta inicial "
        "cuando alternamos la política. La simulación aplica todas las "
        "reglas oficiales; no mueve ninguna unidad gratuitamente.",
        "",
        "**No habilitar una nueva política todavía.** Primero distinguir "
        "si los problemas del primer jugador aparecen en sus tres "
        "decisiones iniciales o después, cuando el rival responde.",
        ""
    ]
    (folder_out/"ai_v402_opening_forensics.md").write_text(
        "\n".join(markdown),encoding="utf-8")
    print("OPEN402_ALL "+json.dumps({k:v for k,v in summary.items()
        if k not in ("pairs",)},ensure_ascii=False,separators=(",",":")))
    print("\n".join(markdown))
    print("PASS TARVOKA v402 aggregate: 64 original asymmetric opening trials and 128 exact mirrored executions")

if __name__=="__main__":
    main(sys.argv[1] if len(sys.argv)>1 else ".ci-v402-logs")
