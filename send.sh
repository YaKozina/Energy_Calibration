#!/bin/sh

#SBATCH --job-name=calibration
#SBATCH --mem=3G
#SBATCH --licenses=sps
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

INDEX=$1

source /sps/nemo/scratch/chauveau/software/falaise/develop/this_falaise.sh

##############################################################################	
#1) Charge2Energy (applies calibration on brio with CD&PTD banks)	
##############################################################################

/sps/nemo/scratch/chauveau/software/falaise/develop/install/bin/flreconstruct \
-i reco-PTD.brio \
-p /.../CalibrationScript/build/Charge2EnergyModule/charge2energy.conf \
-o reco-PTD-c2e.brio


#end
