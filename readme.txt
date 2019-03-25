                        |_   _/  __ \/  __ \_   _|         | |
                          | | | /  \/| /  \/ | | ___   ___ | |
                          | | | |    | |     | |/ _ \ / _ \| |
                          | | | \__/\| \__/\ | | (_) | (_) | |
                          \_/  \____/ \____/ \_/\___/ \___/|_|

  ==============================================================================
  Name:     Transportation Comparison Tool
  Author:   Wessel de Zeeuw - (wessel.dezeeuw@tno.nl)
            Ellen van der Veer
            Joris Koornneef
            Edwin-Jan Tiggelinkhuizen
  Company:  TNO - Department of Applied Geosciences

  Tool Version: 1.2

  ==============================================================================
  Information about the tool:

    This tool is developed for TNO. The main goal for this tool is to make a
    comparison of costs made in different electricity transportation scenarios.
    One of this scenarios consists of the costs made when captured wind energy
    is electrolyzed to H2, compressed and transported through a pipeline. A
    second scenarios is the direct transportation to the Dutch electricity net
    using electricity cables and either AD/DC currents.
    Full documentation and user information  can be found in the accompanying
    documents.

    This tool is only for internal use!!  ©TNO

  Backlog:
  Done
  ------------------------------------------------------------------------------
    - Enabling input of user defined dataset
    - Enabling the adaption of the "main" variables
    - The update of parameter button blocks for faulty changes
    - Implementation of lights indicate the status of computed costs
    - Updating of parameters leads to different light indication for costs
    - Implementation of "Consider new Pipeline" cost module
    - Implementation of "Consider existing Pipeline" cost module
    - Implement XOR New/Existing in the module selection
    - Implementation of "Compression Costs" cost module
    - Incorporate warning messages for hoop stress and pressure drop rates
    - Incorporate the percentage of utilization of flow (and/or leakage)
    - Implementation of results (figures showing breakdown in Capex & Opex)
    - Implementation of results (data breakdown in costs)

  Doing
  ------------------------------------------------------------------------------
    - Enabling the selection of different modules for the Electricity costs
    - Enabling the selection of electrolyse costs
  To Do
  ------------------------------------------------------------------------------
    - Merging code electricity into main application
    - Code checking Pipeline module & variables. 
