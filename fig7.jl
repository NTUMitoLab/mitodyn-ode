# Figure 7 : Summary figure.

using DifferentialEquations
using LabelledArrays
using Parameters
using Setfield
using FromFile
@from "Model/Model.jl" using Model
@from "Model/utils.jl" import second, μM, mV, mM, Hz

# Plotting
import PyPlot as plt
rcParams = plt.PyDict(plt.matplotlib."rcParams")
rcParams["font.size"] = 14
rcParams["font.sans-serif"] = "Arial"
rcParams["font.family"] = "sans-serif"

function fig8data(p, glc = range(3.0mM, 30.0mM, length=101))
    us = map(glc) do g
        param = setglc(p, g)
        prob = SteadyStateProblem(model!, u0, param)
        sol = solve(prob, DynamicSS(Rodas5(), tspan=tend))
        u = sol.u
    end
    jANT = [1//3 * p.f1fo(u.adp_c, u.dpsi, u.ca_m) for u in us]
    jHL = [ p.hleak(u.dpsi) for u in us]
    ff = (p.K_FUSE / p.K_FISS) .* jANT ./ jHL
    return (; jANT, jHL, ff)
end

glc = range(3.0mM, 30.0mM, length=136)  # Range of glucose
tend = 3000.0second  # Time span
# Initial conditions
u0 = LVector(g3p = 2.8μM,
             pyr = 8.5μM,
             nadh_c = 1μM,
             nadh_m = 60μM,
             atp_c = 4000μM,
             adp_c = 500μM,
             ca_m = 0.250μM,
             dpsi = 100mV,
             x2=0.25,
             x3=0.05)

param0 = MitoDynNode()
paramHL = @set param0.hleak.P_H *= 5
paramF1 = @set param0.f1fo.VMAX *= 0.1
paramETC = @set param0.etc.VMAX *= 0.1
paramDM = let rPDH = 0.5, rETC = 0.75, rHL  = 1.4, rF1  = 0.5
    p = @set param0.pdh.VMAX *= rPDH
    p = @set p.hleak.P_H *= rHL
    p = @set p.f1fo.VMAX *= rF1
    p = @set p.etc.VMAX *= rETC
end


function plot_fig7(param0, paramHL, paramF1, paramETC, paramDM;
                   figsize=(12,6))

    # Data
    y1 = fig8data(param0, glc)
    yHL = fig8data(paramHL, glc)
    yF1 = fig8data(paramF1, glc)
    yETC = fig8data(paramETC, glc)
    yDM = fig8data(paramDM, glc)

    xx = glc ./ 5

    fig, ax = subplots(1, 2, figsize=figsize)
    ax[1].plot(xx, y1.ff, "b-", label="Baseline")
    ax[1].plot(xx, yDM.ff, "r-", label="Diabetic")
    ax[1].plot(xx, yETC.ff, "g-", label="Rotenone")
    ax[1].plot(xx, yF1.ff, "c-", label="Oligomycin")
    ax[1].plot(xx, yHL.ff, "k-", label="Uncoupler")
    ax[1].legend(loc="upper right")
    ax[1].set(xlabel="Glucose (X)", ylabel="Fusion / Fission rate")
    ax[1].set_title("A", loc="left")

    ax[2].plot(y1.jHL, y1.jANT, "b-",  label="Baseline")
    ax[2].plot(y1.jHL[1:5:end], y1.jANT[1:5:end], "bo")
    ax[2].plot(yDM.jHL, yDM.jANT, "r-", label="Diabetic")
    ax[2].plot(yDM.jHL[1:5:end], yDM.jANT[1:5:end], "ro")
    ax[2].plot(yETC.jHL, yETC.jANT, "g-",label="Rotenone")
    ax[2].plot(yETC.jHL[1:5:end], yETC.jANT[1:5:end], "go")
    ax[2].plot(yF1.jHL, yF1.jANT, "c-", label="Oligomycin")
    ax[2].plot(yF1.jHL[1:5:end], yF1.jANT[1:5:end], "co")
    ax[2].plot(yHL.jHL, yHL.jANT, "k-", label="Uncoupler")
    ax[2].plot(yHL.jHL[1:5:end], yHL.jANT[1:5:end], "ko")

    ax[2].set(xlabel="Proton leak rate (mM/s)", ylabel="ATP synthase rate (mM/s)")
    ax[2].set_title("B", loc="left")
    ax[2].legend()

    return fig
end

fig7 = plot_fig7(param0, paramHL, paramF1, paramETC, paramDM)

fig7.savefig("Fig7.pdf")
