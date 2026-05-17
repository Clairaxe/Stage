#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Population Analyses of Hippocampus–Amygdala Interactions],

  authors: (
    (
      name: "Claire Chambaz",
    ),
    (
      name: "Claire Meissner Bernard",
    ),
  ),
)

#set par(
  spacing: 1em,
)

= Introduction

Understanding how brain regions coordinate their activity to support emotional memory is a central question in neuroscience. In particular, interactions between the hippocampus (HPC) and the basolateral amygdala (BLA) are known for playing an important role in the encoding, consolidation, and retrieval of emotionally salient experiences.

This project is based on the dataset introduced by Girardeau et al. @Girardeau2017, which investigates coordinated neural activity between hippocampus and amygdala during an associative learning task. In this experiment, rats repeatedly traverse a linear track where an aversive stimulus (air puff) is delivered at a fixed spatial location. Over time, animals learn to associate a specific traversal direction with the occurrence of this aversive event.

The data consist of simultaneous multi-unit recordings from multiple brain regions, including hippocampus and basolateral amygdala. The main objective of my internship is to identify latent structures in neural population activity. From the observable data (eg: firing rates of neurons, events, speed, position over time), find a pattern or a subset of neurons that explain the data and associated behavior. This is interesting as it would allow us to better understand how in a strong emotional context, memory is encoded and retrieved in the hippocampus and basolateral amygdala. To this end, we explore several dimensionality reduction techniques, including:

- Principal Component Analysis (PCA)
- Non-negative Matrix Factorization (NMF)

The hippocampus and basolateral amygdala are major components of the brain located in the limbic system (@fig1). The HPC is a central structure for episodic memory and spatial navigation. It is well known for containing place cells, neurons that fire selectively when the animal occupies a specific position in space. The BLA is involved in processing emotional significance, particularly in fear learning and aversive conditioning. Rather than encoding spatial structure, the amygdala assigns value to stimuli and events, signaling whether they are behaviorally relevant, rewarding, or threatening.

#figure(
  image("images/limbic_system.png", width: 110%),
  caption: [Primary components of the limbic system],
) <fig1>

Episodic memory refers to the ability to encode and retrieve specific events, including their spatial context, temporal structure, and associated emotional content. These different aspects are supported by interacting brain systems rather than a single region. In particular, the hippocampus and the amygdala play complementary roles in episodic memory formation, especially when events are emotionally salient.


= Dataset and Preprocessing

== Task and dataset

Rats were pretrained to run back and forth on a linear track for water as rewards (@fig2). There are three blocks to the task:

- Prerun: Behavioral test session on the track without the air puff (followed by pre-learning sleep in the home cage)
- Run: An aversive air puff is added at the same location of the track on each lap in one of the running directions (followed by a post-learning sleep)
- Postrun: Session without the air puff (to study memory retrieval)

#figure(
  grid(
    rows: 2,
    gutter: 5pt,

    [
      #image("images/linearTrack.png", width: 100%)
    ],

    [
      #image("figures/spatial_trajectory_rat8_postrun.png", width: 100%)
    ],
  ),
  caption: [
    Drawing of linear track (box has the length of 180 cm) and spatial trajectory of Rat 8 during the post-run session.
  ],
) <fig2>

We have neuronal activity (in Hz), which consists of binned spikes from each session. Time bins are 50ms. We also have the normalized position in the box, x and y position during all the sessions. Reward and shock delivery, if an airpuff was delivered during the time bin and finally, information about neurons (most importantly brain regions and neuronal types). We focus on two sessions: Session 6 from Rat 8 and Session 16 from Rat 11. These sessions contain the largest number of simultaneously recorded neurons in both regions, making them suitable for population-level analyses (@table1). We will only focus on the neurons in the dorsal hippocampus (dHPC) and the right amydgala (rAMY).

#figure(
  table(
    columns: 3,
    [], [Rat 8], [Rat 11],
    [cells dHPC], [55], [62],
    [cells rAMY], [57], [53],
    [cells lAMY], [26], [65],

  ),
  caption: [Number of excitatory neurons in each regions for both sessions],
) <table1>


== Lap Detection

The animal repeatedly traverses the corridor between the two extremities of the track. However, it frequently pauses at reward locations located at the extremities. Including these pauses would artificially inflate traversal duration and introduce behavioral variability unrelated to locomotion. So, the analysis was restricted to the central portion of the track: $x in [0.25, 0.85]$

We therefore define three spatial zones:

- Left zone: $x \leq 0.25$
- Right zone: $x \geq 0.85$
- Corridor: $0.25 < x < 0.85$

A lap is defined as a complete traversal between extremities:

- Left-to-right (LR)
- Right-to-left (RL)

Operationally, a lap begins when the animal exits one extremity and enters the corridor, and ends when it reaches the opposite extremity. Short tracking interruptions and brief backtracking movements are ignored to ensure robust segmentation (@fig3). To be more precise, missing tracking bins are skipped, and incomplete crossings are discarded when the animal returns to its starting side before reaching the opposite side.

#figure(
  image("figures/lap_segmentation_rat8_run.png", width: 100%),
  caption: [Example of positional tracking and detected laps during post-run session of Rat 8. Red segments correspond to laps traversed in the danger-associated direction and green segments,t safe laps.],
) <fig3>

For each lap we extract:

- Lap index
- Direction (+1 for LR, -1 for RL)
- Traversal duration

== Neural Data Preprocessing

Neural activity was recorded simultaneously from hippocampus and basolateral amygdala. All analyses were restricted to excitatory neurons. Neural activity matrices take the form $X in RR^(T times N)$ where $T =$ number of time bins and $N =$ number of neurons. Each row represents the instantaneous population state at a given time bin. Neural activity was z-scored across time for each neuron. This ensures that neurons with higher firing rates do not dominate the variance structure. Normalization was applied prior to PCA and nNMF.

== Extraction of Danger vs Safe Samples

The position of the puff changes across sessions, so to minimize variability, neural activity was extracted only when the animal was within ±20 cm of the air-puff location.

Passages through this region were classified as:

+ *Danger*: traversal direction associated with air-puff delivery
+ *Safe*: traversal direction without air-puff

Which gives us two matrices:

$
X^("danger") in RR^(T_d times N)
$

$
X^("safe") in RR^(T_s times N)
$

Where $T_d$ is the number of time bins associated to the danger direction, and $T_s$, the safe direction. These matrices were concatenated for PCA.

= Principal Component Analysis

== Conceptual Framework

Neural population activity at time $t$ can be viewed as a point in an $N$-dimensional space:

$
X_(t:) in RR^N
$

As the animal moves through the environment, the population state evolves over time, tracing a trajectory in this neural state space. Principal Component Analysis identifies the directions of maximal variance in this space and creates a new space defined by patterns of neuronal coactivations. The decomposition can be written as:

$
Z = X W
$

where:

+ $Z$ are the *scores* (describe the position of the neural population state)
+ $W$ are the *loadings* (describe how individual neurons contribute to each population axis)

== Time-bin PCA and Explained Variance

#figure(
  grid(
      columns: 2,
      rows: 2,
      gutter: 10pt,
        [
          #image("figures/pca_scores_rat8.png", width: 100%)
        ],

        [
          #image("figures/pca_scores_rat11.png", width: 100%)
        ],

        [
          #image("figures/scree_plot_rat8.png", width: 100%)
          #align(center)[*Rat 8*]  
        ],

        [
          #image("figures/scree_plot_rat11.png", width: 100%)
          #align(center)[*Rat 11*]
        ],
  ),

  caption: [
    The top figures represent PCA scores (PC1 vs PC2) on the run session of both rats.  
    Each point corresponds to a time bin of neural population activity. 
    The bottom figures correspond to the explained variance for each principal components.
  ],
) <fig4>

In @fig4, the PCA score plots reveal a moderate separation between time bins associated with the dangerous and safe directions, especially for Rat 11. Since PCA is fully unsupervised, this suggests that the behavioural context contributes to the dominant modes of neural population variability.

However, the scree plots indicate that variance is broadly distributed across components, with PC1 accounting for only about 5% of the total variance. Therefore, the observed separation should not be interpreted as evidence for a simple low-dimensional coding of danger, but rather as a distributed effect in a high-dimensional neural representation.

== Loadings

#figure(
  grid(
    columns:  2,
    gutter: 10pt,
    
    [
      #image("figures/pca_loadings_rat8.png", width: 100%)
      #align(center)[*Rat 8*]  
    ],

    [
      #image("figures/pca_loadings_rat11.png", width: 100%)
      #align(center)[*Rat 11*]
    ],
  ),

    caption: [
      PCA loadings showing neuron contributions to the two first components.
    ],
) <fig5>

Loadings indicate how strongly each neuron contributes to the first two principal components (@fig5). In both rats, neurons from the hippocampus tend to display larger loading magnitudes than amygdalar neurons.

== Neurons Contributing Most to Population Axes

To better understand which neurons contribute to the first two PCA axes, we selected neurons whose absolute loading on PC1 or PC2 exceeded 0.3 (@fig6).

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/top_9_rat11.png", width: 100%)
    ],

    [
      #image("figures/hpc_top_neurons_rat11.png", width: 100%)
    ],
  ),

  caption: [
    Neurons with large PCA loadings in Rat 11 run session. Left: loading space for PC1 and PC2 where circled points correspond to neurons with absolute loading greater than 0.3 on PC1 or PC2. Right: mean firing rate during danger and safe traversals for the same selected neurons. Dark blue indicates neurons with stronger contribution to PC1, and light blue indicates neurons with stronger contribution to PC2.
  ],
) <fig6>

Points below the diagonal correspond to neurons with higher average firing rates during danger traversals, whereas points above the diagonal correspond to neurons more active during safe traversals. Neurons with stronger contributions to PC1 appear to be preferentially active during danger traversals, while neurons contributing more strongly to PC2 appear more active during safe traversals.

To examine temporal structure across laps, firing rates of the neurons with the strongest contributions to PC1 and PC2 were plotted across successive laps (@fig7). Randomly selected control neurons from the same region were also displayed for comparison.

#figure(
  grid(
    rows: 2,
    gutter: 10pt,
    [
      #image("figures/hpc_top_neurons_lap_rat11.png", width: 100%)
    ],
    [
      #image("figures/hpc_top_control_neurons_lap_rat11.png", width: 100%)
    ],
  ),

  caption: [
    Firing rates across laps for Rat 11. Top: neurons with the strongest contributions to PC1 and PC2. Bottom: randomly selected control neurons from the same region. Red shaded areas indicate danger laps.
  ],
) <fig7>

The neurons contributing most strongly to PCA exhibit clearer lap-to-lap modulation than the control neurons. In particular, the neuron associated primarily with PC1 displays increased activity during danger laps, whereas the neuron associated primarily with PC2 shows higher activity during safe laps. The modulation is almost binary, these temporal patterns are consistent with the interpretation that the first two PCA axes partly capture behavioural-context-dependent population dynamics.

== Summary of PCA Findings

Overall, PCA suggests that neural population activity does not cluster strongly by condition at the level of instantaneous time bins.

Instead:

+ Population variability is distributed across many dimensions.
+ Neurons from HPC and BLA jointly contribute to population axes.
+ Some neurons exhibit clear firing differences between danger and safe conditions.

= Time Warping and Event Alignment

A main motivation for introducing time warping was to prepare the data for tensor-based population analyses. Without normalization, laps have different durations and cannot be stacked directly into a coherent neuron × time × lap representation. By mapping all traversals onto a common axis, warping makes it possible to build structured three-dimensional arrays suitable for non-negative matrix factorization, and more generally for tensor decomposition methods such as those considered in @Pellegrino2024.

== Puff-Centered Time Warping

We first took the spatial position of the air puff, denoted $x_"puff"$. For each lap, we then restricted the analysis to the segment of trajectory contained in a spatial window of ±20 cm around this position. We identified within each lap, the time bin whose position was closest to $x_"puff"$. This bin was used as an anchor point and treated as the temporal center of the warped segment.

Each lap was then divided into two parts:

+ the portion before the puff-centered anchor
+ the portion after the puff-centered anchor

These two portions were resampled separately by linear interpolation so that all laps were mapped onto the same number of bins. In practice, we used 31 warped bins:

+ 15 bins before the puff
+ 1 central bin aligned with the puff
+ 15 bins after the puff

After warping, neural activity can be represented as a third-order tensor

$
X in RR_+^(N times T times L)
$

where:

+ $N$ is the number of selected neurons
+ $T$ is the number of warped time bins
+ $L$ is the number of laps

Each slice $X_(:,:,l)$ represents the activity of the full neural population during lap $l$.

However, although puff-centered time warping aligns all laps at the puff, it does not guarantee that a given warped time bin corresponds to exactly the same spatial position across laps. Because speed is not always constant, two traversals may differ not only in duration but also in how position evolves relative to time before and after the puff.

To assess this point, we examined, for each warped time bin, the distribution of spatial positions represented across laps.  
This analysis showed that puff-centered warping successfully aligns the central event, but that bins away from the center may still correspond to a range of nearby positions (@fig8).

#figure(
  image("figures/position_timewarp.png", width: 85%),
  caption: [Puff-centered time warping],
) <fig8>

== Position-Based Warping

We implemented a second normalization procedure in which neural activity was interpolated directly onto a common spatial grid spanning the puff zone. In this case, each normalized bin corresponds to a fixed spatial position rather than a fixed normalized time (@fig9). This approach eliminates residual spatial variability across laps and makes it possible to compare neural activity at matched positions along the track.

#figure(
  image("figures/forced_position_timewarp.png", width: 85%),
  caption: [Position-based warping]
  ) <fig9>

The two approaches therefore emphasize different aspects of the data:

+ puff-centered time warping preserves an event-centered temporal interpretation
+ position-based warping preserves strict spatial correspondence across laps

Comparing these two representations helps disentangle whether observed neural structure reflects temporal dynamics around the puff or residual spatial coding.

== Visualization of Warped Neural Activity

To illustrate the effect of the two normalization procedures, we visualized lap-by-lap activity for selected neurons around the puff zone (@fig10).

The upper panel displays activity after puff-centered warping, in which the puff event is aligned at the center of the representation. The lower panel displays activity after position-based warping, where bins correspond to matched spatial locations along the track.

For the neuron 189 (neuron with the largest PC2 loading), activity is concentrated after the puff location and primarily in the safe direction. The similarity between the two warpings suggests that the response is relatively robust to both normalizations.

#figure(
  image("figures/neuron189_warped.png", width: 100%),
  caption: [Comparison of puff-centered and position-based warping for a representative neuron. Rows correspond to laps and columns to normalized bins. Laps are sorted by condition: safe laps appear in the first half of each panel and dangerous laps in the second half. The cyan horizontal line marks the separation between the two groups.],
) <fig10>

= Non-negative Matrix Factorization

Unlike PCA, which represents activity using orthogonal components that may contain positive and negative values, NMF constrains all coefficients to remain non-negative. As a result, neural activity is represented as an additive combination of latent components, often leading to more interpretable population patterns. In practice, NMF tends to identify groups of neurons, laps, or temporal motifs that co-activate together.

After warping, neural activity is represented as a tensor

$
X in RR_+^(N times T times L),
$

where $N$ is the number of neurons, $T$ is the number of warped time bins, and $L$ is the number of laps. Since NMF is a matrix factorization method, this tensor must first be reshaped into a two-dimensional matrix. We therefore considered three complementary slicing strategies, leading to three different NMF decompositions from the same warped tensor:

+ time slicing reshapes the tensor into a matrix of size $(T L) times N$ and extracts temporal motifs around the puff
+ neuron slicing reshapes the tensor into a matrix of size $(N T) times L$ and extracts groups of laps with similar population activity profiles
+ lap slicing reshapes the tensor into a matrix of size $(N L) times T$ and extracts temporal patterns shared across neurons and laps

== Neuron Slicing

In neuron slicing, the warped tensor is reshaped into a matrix of size $(N T) times L$. Applying NMF to this matrix identifies groups of laps sharing similar population activity patterns (@fig11).

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/nmf_neuron_component1.png", width: 100%)
    ],

    [
      #image("figures/nmf_neuron_component3.png", width: 100%)
    ],
  ),

  caption: [
    NMF HPC neuron slicing for Rat 11.
    Left: temporal activity associated with NMF component 1 across laps.
    Right: temporal activity associated with NMF component 3 across laps.
    Each curve corresponds to one lap, with colors indicating safe (green) and dangerous (red) traversals.
  ],
) <fig11>

#figure(
  table(
    columns: 4,
    align: center,
    inset: 6pt,
    stroke: 0.5pt + gray,

    fill: (x, y) => {
      if y == 0 {
        rgb("#e0e4e9")
      } else if y in (1, 3) {
        rgb("#8FB8FF")
      } else {
        rgb("#C7DCFF")
      }
    },

    [Method], [Component], [Top neurons], [Weights / Loadings],

    [NMF], [Component 1], [*150, 147*, 185], [10.1143, 2.7723, 1.4259],
    [PCA], [PC1], [*147, 150*, 205], [+0.4400, +0.4050, +0.3733],

    [NMF], [Component 3], [*189, 148, 155*], [1.3637, 0.2836, 0.2713],
    [PCA], [PC2], [*189, 148, 155*], [+0.4749, +0.3840, +0.3775],
  ),

  caption: [
    Top 3 neurons of the HPC contributing most strongly to selected NMF components and PCA components for Rat 11 run session
  ]
) <table2>

In the @table2, the dominant neurons identified by NMF components match those associated with the leading PCA components (@fig6), suggesting that both decompositions capture related population structure despite relying on different decompositions.

== Time Slicing

#figure(
  image("figures/nmf_time_slicing_profiles.png", width: 70%),
  caption: [
    Time slicing for Rat 11 run session (HPC neurons). Each curve corresponds to one component of $W_"time"$. The dashed vertical line indicates the puff-aligned bin.
  ],
) <fig12>

These components summarize dominant temporal motifs of population activity around the puff event (@fig12).

== Lap Slicing

#figure(
  image("figures/nmf_lap_slicing.png", width: 80%),
  caption: [
    NMF lap slicing for Rat 11 run session (HPC neurons).
    Each point corresponds to one lap and shows its weight the first component.
    Colors indicate danger (red) and safe (green) traversals.
  ],
) <fig13>

In @fig13, the different NMF components exhibit distinct relationships with behavioral condition. Components 1 and 4 are expressed predominantly during dangerous laps, whereas components 3 and 5 are more strongly associated with safe laps. Component 2 appears less condition-specific and may instead reflect variability shared across both traversal types. Overall, these results suggest that lap-level population activity contains structured patterns related to behavioral context around the puff zone.

== Summary

Across PCA and NMF analyses, neural population activity around the puff zone exhibited a clear low-dimensional organization. Several latent components were associated with behavioral condition, with some components being expressed predominantly during dangerous traversals and others during safe traversals.

The comparison between puff-centered and position-based warping further suggested that population activity combines both temporal and spatial organization. Some neurons appeared relatively robust to the normalization scheme, whereas others displayed sharper structure under one representation or the other.

Neuron slicing additionally revealed structured groups of co-active neurons. Importantly, the neurons contributing most strongly to several NMF components overlapped substantially with those identified by PCA, suggesting that the observed population structure is robust across different dimensionality reduction methods.

Overall, these analyses indicate that HPC and BLA population activity around the puff zone is not random or purely local, but instead organized into coordinated latent patterns related to traversal dynamics and behavioral context.


= Discussion

The present analyses suggest that neural population activity in HPC and BLA contains structured representations associated with traversal of the puff zone. Both PCA and NMF consistently revealed low-dimensional population structure that partially separates dangerous and safe traversals, indicating that behavioral context is reflected at the level of coordinated neural assemblies.

Importantly, this structure was not exclusively locked to the puff event itself. The comparison between puff-centered and position-based warping showed that some activity patterns remained stable under both normalization schemes, suggesting that neural responses combine temporal dynamics around the puff with spatial coding along the track.

The NMF analyses further suggested that different latent population modes may be preferentially recruited during dangerous versus safe traversals. Because NMF components are additive and nonnegative, these latent patterns can naturally be interpreted as partially distinct population assemblies.

Another important observation is that several dominant neurons were identified consistently across PCA and NMF analyses. This convergence suggests that the extracted structure reflects robust properties of the population activity rather than artifacts of a specific decomposition method.

An important next step will be to characterize more precisely the anatomical organization of these latent components. In particular, it will be interesting to determine whether the identified assemblies remain confined within HPC or BLA, or instead involve coordinated activity spanning both regions. Such mixed components could reflect inter-regional communication during emotionally salient navigation.

There is much more to try !

+ communication subspace analyses @Semedo2020Review
+ slice tensor component analysis @Pellegrino2024

= References

#bibliography("references.bib")