#===
# Figure 5

Calcium oscillation
===#
using DifferentialEquations
using ModelingToolkit
using DisplayAs: PNG
using MitochondrialDynamics
using MitochondrialDynamics: second, μM, mV, mM, Hz, minute
import PythonPlot as plt
plt.matplotlib.rcParams["font.size"] = 14

#---
@named sys = make_model()
@unpack Ca_c, GlcConst = sys
ssprob = SteadyStateProblem(sys, [], [GlcConst => 10mM])
sssol = solve(ssprob, DynamicSS(TRBDF2()))
caavg = sssol[Ca_c]

# Calcium wave independent from ATP:ADP ratio
function cac_wave(t, amplitude=1.5)
    ca_r = 0.09μM
    period = 2minute
    ka_ca = (caavg - ca_r) * amplitude
    x = 5 * ((t / period) % 1.0)
    return ca_r + ka_ca * (x * exp(1 - x))^4
end

@variables t
@register_symbolic cac_wave(t)
@named sysosci = make_model(; caceq=Ca_c~cac_wave(t))

#---
alg = TRBDF2()
tend = 2000.0
ts = range(1520.0, tend; step=2.0)
prob = ODEProblem(sysosci, [], tend, [GlcConst => 10mM])
sol = solve(prob, alg, saveat=ts)

#---
function plot_fig5(sol, figsize=(10, 10))
    ts = sol.t
    tsm = ts ./ 60
    @unpack Ca_c, Ca_m, ATP_c, ADP_c, ΔΨm, degavg, J_ANT, J_HL = sys
    fig, ax = plt.subplots(5, 1; figsize)

    ax[0].plot(tsm, sol[Ca_c * 1000], label="Cyto. Ca (μM)")
    ax[0].plot(tsm, sol[Ca_m * 1000], label="Mito. Ca (μM)")
    ax[0].set_title("A", loc="left")

    ax[1].plot(tsm, sol[ATP_c / ADP_c], label="ATP:ADP")
    ax[1].set_title("B", loc="left")

    ax[2].plot(tsm, sol[ΔΨm * 1000], label="ΔΨm (mV)")
    ax[2].set_title("C", loc="left")

    ax[3].plot(tsm, sol[degavg], label="Average node degree")
    ax[3].set_title("D", loc="left")

    ax[4].plot(tsm, sol[J_ANT], label="ATP export (mM/s)")
    ax[4].plot(tsm, sol[J_HL], label="H leak (mM/s)")
    ax[4].set_title("E", loc="left")
    ax[4].set(xlabel="Time (minute)")

    for i in 0:4
        ax[i].grid()
        ax[i].legend(loc="center left")
        ax[i].set_xlim(tsm[begin], tsm[end])
    end

    plt.tight_layout()
    return fig
end

#---

fig5 = plot_fig5(sol);
fig5 |> PNG

# Export figure
exportTIF(fig5, "Fig5-ca-oscillation.tif")
