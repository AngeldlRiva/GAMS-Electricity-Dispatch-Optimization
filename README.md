
# GAMS Electricity Dispatch Optimization

This repository contains a GAMS model for optimizing electricity generation dispatch. The model integrates various energy sources including thermal, nuclear, photovoltaic, wind, and hydraulic generation. It also considers start-up/shutdown costs and wind power uncertainty through a stochastic formulation.

## Overview

The repository includes several model variants:
- **Model 1 (Base Model):** Optimizes generation while meeting demand using all available energy sources.
- **Model 1 (Without Hydraulic):** Computes the cost excluding hydraulic (water) generation.
- **Model 2 (Price-Based):** Incorporates an electricity price variable calculated from unit costs.
- **Model 3 (Start-up/Shutdown Costs):** Adds binary variables to capture start-up and shutdown decisions.
- **Model 4 (Stochastic):** Considers multiple wind production scenarios with associated probabilities.

## Model Details

- **Sets:** Define groups of thermal units, time blocks, hydraulic groups, and stochastic scenarios.
- **Parameters:** Include maximum/minimum power, ramp limits, cost coefficients, renewable capacities (nuclear, photovoltaic, wind), demand, and hydraulic contributions.
- **Variables:** Represent generation levels, unit on/off statuses, hydraulic generation, reserve levels, and total cost.
- **Equations:** Cover demand satisfaction, ramping constraints, generation limits, hydraulic balance, and other operational constraints.

## Requirements

- [GAMS](https://www.gams.com/) must be installed on your system.
- A valid GAMS license is required to run the model.
