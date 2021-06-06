library('DiagrammeR')

grViz("
digraph data_generation {

  graph[rankdir = TD
  label = 'Data Generation Process'
  labelloc = t
  fontsize = 25]

      subgraph cluster_0{
      
      graph[shape = rectangle
      label = 'Individual-level'
      labelloc = t
      fontsize = 25
      rankdir = TD]
      
      node[shape = 'box']
      b[label = 'Logit@^{1}', shape = 'cylinder']
      c[label = 'Predict probability of return']
      d[label = 'Generate return status']
      e[label = 'Non-returning students']
      f[label = 'Returning Student list']
      n[label = 'rnorm@^{3}', shape = 'cylinder']
      r[label = 'sample 0/1@^{4}', shape = 'cylinder']
      s[label = '0 Credits']
      t[label = 'Generate credit load']
      
      {rank = same; b, c}
      {rank = same; e, f}
      {rank = same; r, d}
      {rank = same; n, t, s}
      
      #edges
      b -> c
      d -> {e, f}
      c -> d
      r -> d
      e -> s
      f -> t
      n -> t
      }
      
      subgraph cluster_1{
      graph[shape = rectangle
      label = 'Aggregate-level'
      labelloc = t
      fontsize = 25]
      
      node[shape = 'box']
      g[label = 'Predict # of new students']
      h[label = 'OLS@^{2}', shape = 'cylinder']
      i[label = 'Sample credit load']
      m[label = 'rnorm@^{3}', shape = 'cylinder']
      o[label = 'Generate individual values']
      v[label = 'Sample gender + credits@^{5}', shape = 'cylinder']
      
      {rank = same; g, h}
      {rank = same; i, m}
      {rank = same; v, o}
      
      #edges
      m -> i
      h -> g
      g -> o
      o -> i
      v -> o
      }
      
      subgraph cluster_2{
      graph[label = 'Footnotes'
      labelloc = t
      penwidth = 0
      ranksep = 0.02]
      
      node[shape = 'none']
      x[label = '1: logit(y) = \u03b2*Gender + \u03b2*Cumulative credits + c(function of GDP) + \u03b5', x = 1, y = 1]
      y[label = '2: y = \u03b2*GDP + c + \u03b5']
      z[label = '3: truncated (1, 21) rnorm(\u03bc = 9, \u03c3 = 3)']
      aa[label = '4: sample, p(1) = see footnote 1']
      ab[label = '5: sample, p(Female) = 0.5; credit load = see footnote 3']
      
      
      #edges
      x -> y[style = 'invis']
      y -> z[style = 'invis']
      z -> aa[style = 'invis']
      aa -> ab[style = 'invis']
      }

      node[shape = 'box']
      a[label = 'Students @ t-1']
      j[label = 'Join']
      l[label = 'New students']
      q[label = 'Students @ t']
      u[label = 'Returning students']
      w[label = 'If t-1 = 0, generate individual values@^{5}']
      
      #edges
      a -> c
      i -> l
      {l, u} -> j
      j -> q
      t -> u
      w -> a
      m -> x[style = 'invis']
      
      {rank = same; a, w}
}")
