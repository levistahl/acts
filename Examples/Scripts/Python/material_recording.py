#!/usr/bin/env python3
import os
import warnings
import pathlib

import acts
from acts.examples import (
    GaussianVertexGenerator,
    ParametricParticleGenerator,
    FixedMultiplicityGenerator,
    EventGenerator,
    RandomNumbers,
)


import acts.examples.geant4
import alice3
u = acts.UnitConstants

_material_recording_executed = False


def runMaterialRecording(g4geo, outputDir, tracksPerEvent=10000, s=None):
    global _material_recording_executed
    if _material_recording_executed:
        warnings.warn("Material recording already ran in this process. Expect crashes")
    _material_recording_executed = True

    rnd = RandomNumbers(seed=228)

    s = s or acts.examples.Sequencer(events=10000, numThreads=1)

    evGen = EventGenerator(
        level=acts.logging.INFO,
        generators=[
            EventGenerator.Generator(
                multiplicity=FixedMultiplicityGenerator(n=1),
                vertex=GaussianVertexGenerator(
                    stddev=acts.Vector4(0, 0, 0, 0),
                    mean=acts.Vector4(0, 0, 0, 0),
                ),
                particles=ParametricParticleGenerator(
                    pdg=acts.PdgParticle.eInvalid,
                    charge=0,
                    randomizeCharge=False,
                    mass=0,
                    p=(1 * u.GeV, 10 * u.GeV),
                    eta=(-4, 4),
                    numParticles=tracksPerEvent,
                    etaUniform=True,
                ),
            )
        ],
        outputParticles="particles_initial",
        randomNumbers=rnd,
    )

    s.addReader(evGen)

    g4AlgCfg = acts.examples.geant4.makeGeant4MaterialRecordingConfig(
        level=acts.logging.INFO,
        detector=g4geo,
        inputParticles=evGen.config.outputParticles,
        outputMaterialTracks="material_tracks",
        randomNumbers=rnd,
    )

    g4AlgCfg.detectorConstruction = g4geo

    g4Alg = acts.examples.geant4.Geant4Simulation(
        level=acts.logging.INFO, config=g4AlgCfg
    )

    s.addAlgorithm(g4Alg)

    s.addWriter(
        acts.examples.RootMaterialTrackWriter(
            prePostStep=True,
            recalculateTotals=True,
            collection="material_tracks",
            filePath=os.path.join(outputDir, "geant4_material_tracks.root"),
            level=acts.logging.INFO,
        )
    )

    return s


if "__main__" == __name__:

    geo_dir = pathlib.Path.cwd()
    detector, trackingGeometry, decorators = alice3.buildALICE3Geometry(
    geo_dir, True, False, acts.logging.VERBOSE)

    gdml_file = "output.gdml"
    g4geo = acts.examples.geant4.GdmlDetectorConstruction(gdml_file)

    runMaterialRecording(g4geo=g4geo, tracksPerEvent=100, outputDir=os.getcwd()).run()
