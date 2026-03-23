#set page(
  margin: 1in,
)

#set text(
  size: 11pt,
)

#set heading(numbering: "1.")

#set par(justify: true)

#set math.equation(numbering: none)

#show heading.where(level: 1): it => block[
  #set text(size: 18pt, weight: "bold")
  #it
]

#show heading.where(level: 2): it => block[
  #set text(size: 14pt, weight: "bold")
  #it
]

#show heading.where(level: 3): it => block[
  #set text(size: 12pt, weight: "bold")
  #it
]

#align(center)[
  #text(size: 20pt, weight: "bold")[Internship Report]
  #linebreak()
  #text(size: 14pt)[Population Analyses of Hippocampus–Amygdala Interactions]
  #linebreak()
  Claire Chambaz
]

= Introduction

Understanding how distributed brain regions coordinate their activity to support emotional memory is a central question in systems neuroscience.  
In particular, interactions between the hippocampus (HPC) and the basolateral amygdala (BLA) are thought to play a key role in the encoding and consolidation of emotionally salient experiences.

This project analyzes neural recordings from Girardeau et al. @Girardeau2017, which investigated coordinated reactivation events between hippocampus and amygdala during emotional learning.

The dataset consists of multi-unit recordings from rats performing repeated traversals along a linear track where an aversive stimulus (air puff) is delivered at a fixed location.

We focus on two sessions with the largest number of simultaneously recorded neurons:

+ Session 13 from Rat 8  
+ Session 27 from Rat 11  

These sessions contain a substantial number of neurons in both hippocampus and amygdala, making them well suited for population-level analyses.

Our objectives are twofold:

+ Identify latent population activity patterns using dimensionality reduction techniques.
+ Explore how neural population activity differs between laps associated with a dangerous direction and laps corresponding to a safe direction.

The analyses presented here aim to characterize the geometry of neural population activity and identify neurons that contribute most strongly to condition-dependent population dynamics.


= Exploratory Analyses and Preprocessing

== Lap Detection and Behavioral Segmentation

Rats repeatedly traverse a linear corridor during the task.

The global spatial organization of the behavior can be appreciated in @fig-trajectory-example, which shows the positional trajectory of the animal during the post-run session.

#figure(
  image("figures/spatial_trajectory_rat8_postrun.png", width: 60%),
  caption: [
    Spatial trajectory of Rat 8 during the post-run session.  
    The animal repeatedly traverses the corridor between the two extremities of the track.
  ],
) <fig-trajectory-example>

Although the animal repeatedly crosses the corridor, it frequently pauses at reward locations located at the extremities.  
Including these pauses would artificially inflate traversal duration and introduce behavioral variability unrelated to locomotion.

To isolate pure locomotor dynamics, the analysis was restricted to the central portion of the track:

$
x in [0.25, 0.85]
$

We therefore define three spatial zones:

+ Left zone: $x <= 0.25$
+ Right zone: $x >= 0.85$
+ Corridor: $0.25 < x < 0.85$

A lap is defined as a complete traversal between extremities:

+ Left-to-right (LR)
+ Right-to-left (RL)

Operationally, a lap begins when the animal exits one extremity and enters the corridor, and ends when it reaches the opposite extremity.

Short tracking interruptions and brief backtracking movements are ignored to ensure robust segmentation.

For each lap we extract:

+ Lap index
+ Direction ($+1$ for LR, $-1$ for RL)
+ Traversal duration

#figure(
  [
    #image("figures/lap_segmentation_rat8_run.png", width: 110%, height: 5cm)
    #v(5mm)
    #image("figures/lap_segmentation_rat8_postrun.png", width: 110%, height: 5cm)
  ],
  caption: [
    Example of positional tracking and detected laps during run and post-run sessions.  
    Only the central corridor is retained for lap analysis.  
    Red segments correspond to laps traversed in the danger-associated direction.
  ],
) <fig-lap-segmentation>

Restricting the analysis to the corridor ensures that neural comparisons are performed during comparable behavioral epochs.


== Behavioral Results

Using this segmentation, lap durations were computed for both rats.

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/LapDuration_points_RUN.png", width: 100%)
    ],

    [
      #image("figures/LapDuration_points_POSTRUN.png", width: 100%)
    ],
  ),
  caption: [
    Lap durations for run and post-run sessions.  
    Each point represents one lap traversal.
  ],
) <fig-lap-duration>

Lap durations vary across traversals, reflecting differences in running speed.  
This variability motivates additional normalization steps in later analyses.


== Neural Data Preprocessing

Neural activity was recorded simultaneously from hippocampus and basolateral amygdala.

All analyses were restricted to **excitatory neurons**, as recommended.

Spike trains were binned in time and converted into firing rates.

Neural activity matrices take the form

$
X in RR^(T times N)
$

where:

+ $T$ = number of time bins  
+ $N$ = number of neurons

Each row represents the instantaneous population state at a given time bin.

Mean firing rates were approximately:

+ Hippocampus: 0.61 Hz  
+ Amygdala: 0.46 Hz  

Because variance scales with firing rate, normalization was applied prior to PCA.


= Principal Component Analysis

== Conceptual Framework

Neural population activity at time $t$ can be viewed as a point in an $N$-dimensional space:

$
X_(t,:) in RR^N
$

As the animal moves through the environment, the population state evolves over time, tracing a trajectory in this neural state space.

Principal Component Analysis identifies the directions of maximal variance in this space.

The decomposition can be written as:

$
Z = X W
$

where:

+ $Z$ are the **scores** (time bins in PCA space)
+ $W$ are the **loadings** (neuron contributions)

Thus:

+ Scores describe the position of the neural population state.
+ Loadings describe how individual neurons contribute to each population axis.


== Data Normalization

Neural activity was z-scored across time for each neuron:

$
X_(t,n)^(z) = (X_(t,n) - mu_n) / sigma_n
$

This ensures that neurons with higher firing rates do not dominate the variance structure.


== Extraction of Danger vs Safe Samples

To focus on behaviorally relevant activity, neural activity was extracted only when the animal was within ±20 cm of the air-puff location.

Passages through this region were classified as:

+ **Danger**: traversal direction associated with air-puff delivery
+ **Safe**: traversal direction without air-puff

This yields two matrices:

$
X^("danger") in RR^(T_d times N)
$

$
X^("safe") in RR^(T_s times N)
$

These matrices were concatenated for PCA.


== Time-bin PCA

#figure(
  grid(
      columns: 2,
      gutter: 10pt,
    
      [
        #image("figures/pca_scores_rat8_timebins.png", width: 100%)
        #align(center)[*Rat 8*]  
      ],

      [
        #image("figures/pca_scores_rat11_timebins.png", width: 100%)
        #align(center)[*Rat 11*]
      ],
  ),

  caption: [
    PCA scores (PC1 vs PC2).  
    Each point corresponds to a time bin of neural population activity.
  ],
) <fig-pca-scores>

In both sessions, danger and safe time bins partially overlap in PCA space.

This indicates that instantaneous population activity does not form clearly separated clusters for the two conditions.

However, some structure is visible, suggesting that condition-related information may be embedded in higher-dimensional population dynamics.

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
      PCA loadings showing neuron contributions to the first components.
    ],
) <fig-pca-loadings>

Loadings indicate which neurons contribute most strongly to each population axis.

In both sessions, hippocampal and amygdala neurons are intermixed in loading space rather than forming separate clusters.

This suggests that the dominant population activity patterns involve **joint contributions from both regions**, rather than independent region-specific dynamics.

== Neurons Contributing Most to Population Axes

To better understand the population axes, neurons with the largest loading magnitudes were selected.

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/vide.jpg", width: 100%)
      #align(center)[*Rat 8*]
    ],

    [
      #image("figures/vide.jpg", width: 100%)
      #align(center)[*Rat 11*]
    ],
  ),

  caption: [
    Mean firing rates of neurons with largest PCA loadings.  
    Each point corresponds to one neuron.
  ],
)

Points below the diagonal correspond to neurons more active during danger traversals, while points above correspond to neurons more active during safe traversals.

These plots show that neurons contributing strongly to PCA axes often exhibit condition-dependent activity differences.

== Lap-Level Dynamics

To examine temporal structure across laps, firing rates of selected neurons were plotted across successive laps.

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/vide.jpg", width: 100%)
      #align(center)[*Rat 8*]
    ],

    [
      #image("figures/vide.jpg", width: 100%)
      #align(center)[*Rat 11*]
    ],
  ),

  caption: [
    Firing rate of selected neurons across laps.
  ],
)

The colored background indicates danger laps.

This representation allows us to visualize whether neurons contributing strongly to population axes show consistent modulation across repeated traversals.


== Summary of PCA Findings

Overall, PCA suggests that neural population activity does not cluster strongly by condition at the level of instantaneous time bins.

Instead:

+ Population variability is distributed across many dimensions.
+ Neurons from HPC and BLA jointly contribute to population axes.
+ Some neurons exhibit clear firing differences between danger and safe conditions.

These findings motivate further analyses focusing on **population dynamics and inter-regional communication**.


= Discussion

These exploratory analyses reveal that hippocampal and amygdala neurons jointly contribute to population activity patterns near the aversive stimulus location.

While PCA does not reveal a simple clustering of neural states by condition, it identifies neurons that contribute strongly to population variability and may participate in encoding behavioral context.

Future analyses will therefore focus on methods designed to capture structured interactions between regions, including:

+ communication subspace analyses @Semedo2020Review
+ tensor decomposition approaches @Pellegrino2024

These approaches aim to reveal structured low-dimensional interactions between hippocampus and amygdala during emotionally relevant behavior.


= References

#bibliography("references.bib")