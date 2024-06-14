import matplotlib.pyplot as plt
import misc
import file_operations as fl
import numpy as np

if __name__ == "__main__":
  misc.to_local_dir(__file__)
  # fname = "TrainingSets_2024-06-12.csv"
  # data = np.array(fl.load_txt(fname, delimiter=",", dtype=str, german_numerals=False))

  # dates = sorted(list(set([d.split(" ")[0] for d in data[:, 1]])))
  # datemap = dict()
  # for i, d in enumerate(dates): datemap[d] = i

  # exercises = sorted(list(set(data[:, 0])))
  

  # trainings = []
  # for i, e in enumerate(exercises):
  #   subtrainings = data[data[:, 0] == e]
  #   trainings.append(subtrainings)

  # weights = []
  # for _ in exercises: weights.append([])

  # for i, t in enumerate(trainings):
  #   weights[i] = [float(w) for w in t[:, 2]]
  
  import itertools as it

  availables = [1.0, 1.0, 1.0, 1.0, 1.25, 1.25, 1.25, 1.25, 2.0, 2.0, 2.5, 2.5, 2.5, 2.5, 5.0, 5.0, 5.0, 5.0, 10.0, 10.0]
  # availables = [1.0, 1.0, 1.0, 1.0, 1.25, 1.25, 1.25, 1.25, 2.0, 2.0, 2.5, 2.5, 2.5, 2.5]
  def powerset(iterable):
    "powerset([1,2,3]) --> () (1,) (2,) (3,) (1,2) (1,3) (2,3) (1,2,3)"
    s = list(iterable)
    return it.chain.from_iterable(it.combinations(s, r) for r in range(len(s)+1))

  target = 5.8 - 2.3
  combis = dict()

  for index, i in enumerate(powerset(availables)):
    thesum = sum(i)
    if thesum in combis:
      if len(combis[thesum]) > len(i):
        combis[thesum] = i
    else:
      combis[thesum] = i

  _weights = [k for k in combis]

  subs = ", ".join([str(w) for w in _weights])
  print(f"List<double> mappableWeights = [{subs}]")
  # for k in combis:
  #   print(k, combis[k])
  print("List<List<double>> weightCombinations = [")

  for k in combis:
    subst = ", ".join([str(_k) for _k in combis[k]])
    print(f"[{subst}],")

  print("]")


  # result = min(powerset(availables), key=lambda seq: abs(sum(seq)-target))
  # print(result)
  # for e, w in zip(exercises, weights):
  #   print(e, w)

