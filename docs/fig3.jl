#===
# Figure 3

Steady-state solutions for a range of glucose concentrations and OXPHOS capacities by chemicals.
===#
using OrdinaryDiffEq
using DiffEqCallbacks
using ModelingToolkit
using MitochondrialDynamics
import PythonPlot as plt
plt.matplotlib.rcParams["font.size"] = 14

#---

@named sys = make_model()
@unpack GlcConst, VmaxF1, VmaxETC, pHleak = sys
parmap = Dict((k,i) for (i, k) in enumerate(parameters(sys)))
iGlc = parmap[sys.GlcConst]
iVmaxF1 = parmap[sys.VmaxF1]
iVmaxETC = parmap[sys.VmaxETC]
ipHleak = parmap[sys.pHleak]
prob = ODEProblem(sys, [], Inf)

# Range for two parameters

rGlcF1 = range(3.0, 30.0, 51)
rGlcETC = range(3.0, 30.0, 51)
rGlcHL = range(4.0, 30.0, 51)
rF1 = range(0.1, 2.0, 51)
rETC = range(0.1, 2.0, 51)
rHL = range(0.1, 5.0, 51)

opts = (
    save_start = false,
    save_everystep = false,
    callback=TerminateSteadyState()
)

function solve_fig3(glc, r, protein, prob; alg=Rodas5())
    idx = parmap[protein]
    p = copy(prob.p)
    p[iGlc] = glc
    p[idx] = prob.p[idx] * r
    return solve(remake(prob, p=p), alg; opts...)
end

@unpack VmaxF1, VmaxETC, pHleak = sys
solsf1 = [solve_fig3(glc, r, VmaxF1, prob) for r in rF1, glc in rGlcF1];
solsetc = [solve_fig3(glc, r, VmaxETC, prob) for r in rETC, glc in rGlcETC];
solshl = [solve_fig3(glc, r, pHleak, prob) for r in rHL, glc in rGlcHL];

#---

function plot_fig3(;
    figsize=(10, 10),
    cmaps=["bwr", "magma", "viridis"],
    ylabels=[
        "ATP synthase capacity (X)",
        "ETC capacity (X)",
        "Proton leak rate (X)"
    ],
    cbarlabels=["<k>", "ΔΨ", "ATP/ADP"],
    xxs=(rGlcF1, rGlcETC, rGlcHL),
    xscale=5.0,
    yys=(rF1, rETC, rHL),
    zs=(solsf1, solsetc, solshl),
    extremes=((1.0, 1.8), (80.0, 180.0), (0.0, 60.0))
)
    ## mapping functions
    @unpack degavg, ΔΨm, ATP_c, ADP_c = sys
    fs = (s -> s[degavg][end], s -> s[ΔΨm * 1000][end] , s -> s[ATP_c / ADP_c][end])

    fig, axes = plt.subplots(3, 3; figsize)

    for col in 1:3
        f = fs[col]
        cm = cmaps[col]
        cbl = cbarlabels[col]
        vmin, vmax = extremes[col]

        ## lvls = LinRange(vmin, vmax, levels)
        for row in 1:3
            xx = xxs[row] ./ xscale
            yy = yys[row]
            z = zs[row]
            ax = axes[row-1, col-1]

            ylabel = ylabels[row]

            mesh = ax.pcolormesh(
                xx, yy, map(f, z);
                shading="gouraud",
                rasterized=true,
                cmap=cm,
                vmin=vmin,
                vmax=vmax
            )

            ax.set(ylabel=ylabel, xlabel="Glucose (X)")

            ## Arrow annotation: https://matplotlib.org/stable/tutorials/text/annotations.html#plotting-guide-annotation
            if row == 1
                ax.text(5.5, 1, "Oligomycin", ha="center", va="center", rotation=-90, size=16, bbox=Dict("boxstyle" => "rarrow", "fc" => "w", "ec" => "k", "lw" => 2, "alpha" => 0.5))
            elseif row == 2
                ax.text(5.5, 1, "Rotenone", ha="center", va="center", rotation=-90, size=16, bbox=Dict("boxstyle" => "rarrow", "fc" => "w", "ec" => "k", "lw" => 2, "alpha" => 0.5))
            elseif row == 3
                ax.text(5.5, 2.5, "FCCP", ha="center", va="center", rotation=90, size=16, bbox=Dict("boxstyle" => "rarrow", "fc" => "w", "ec" => "k", "lw" => 2, "alpha" => 0.5))
            end
            cbar = fig.colorbar(mesh, ax=ax)
            cbar.ax.set_title(cbl)
        end
    end

    fig.tight_layout()
    return fig
end

#---

fig3 = plot_fig3(figsize=(13, 10));
fig3 |> PNG

# Export figure
exportTIF(fig3, "Fig3-2Dsteadystate.tif")
