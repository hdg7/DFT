import sys
import pickle
import os

sys.path.append(os.environ["DFT_HOME"])

import backend.support.functions as functions
import backend.generator.extractFuncConst as genFoc
import backend.visitors.cVisitors.manipulateMain as manipulateMain
import backend.tester.TesterMainPro as TesterMainPro
from pycparser import c_generator


def generate(parameters):
    genera=genFoc.ConstraintInputGenerator(parameters["filename"],parameters["functionName"],parameters["fileZ3"])
    genera.finalSetUp()
    genera.createInput()
    genera.randomParams()
    #inputs=genera.generateInputs(totalInputs,2)
    #genFix=genOut.InputGenerator(fileOriFixed,functionName)
    inputs=[]
    count=0
    failures=0
    while len(inputs) < parameters["totalInputs"] and count  < 1000:
        sol=genera.createInput()
        if sol:
            inputs.append(sol)
        else:
            failures=failures+1
        genera.randomParams()
        count=count+1
    if count < 1000:    
        print("Total calls:" + str(count))
    else:
        print("Total calls:" + str(count-failures))
    return inputs
