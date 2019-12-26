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
     pareto=genera.optimizeParamsGranular()
     inputs=[]
     while len(inputs) < parameters["totalInputs"]:
          sol=genera.createInput()
          if sol: inputs.append(sol)
     return inputs

