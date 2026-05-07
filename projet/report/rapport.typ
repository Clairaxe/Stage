#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Population Analyses of Hippocampus–Amygdala Interactions],

  abstract: [
    I should add an abstract !
  ],

  authors: (
    (
      name: "Claire Chambaz",
    ),
    (
      name: "Claire Meissner Bernard",
    ),
  ),
)                                                              

= Introduction

Understanding how brain regions coordinate their activity to support emotional memory is a central question in neuroscience. In particular, interactions between the hippocampus (HPC) and the basolateral amygdala (BLA) are known for playing an important role in the encoding, consolidation, and retrieval of emotionally salient experiences.

This project is based on the dataset introduced by Girardeau et al. @Girardeau2017, which investigates coordinated neural activity between hippocampus and amygdala during an associative learning task. In this experiment, rats repeatedly traverse a linear track where an aversive stimulus (air puff) is delivered at a fixed spatial location. Over time, animals learn to associate a specific traversal direction with the occurrence of this aversive event.

The data consist of simultaneous multi-unit recordings from multiple brain regions, including hippocampus and basolateral amygdala. We focus on two sessions: Session 13 from Rat 8 and Session 27 from Rat 11. These sessions contain the largest number of simultaneously recorded neurons in both regions, making them suitable for population-level analyses. The main objective of my internship is to identify latent structures in neural population activity. To this end, we explore several dimensionality reduction techniques, including:

- Principal Component Analysis (PCA)
- Time-warping
- Non-negative Matrix Factorization (NMF)

= Biological Background

== Episodic and Emotional Memory

Episodic memory refers to the ability to encode and retrieve specific events, including their spatial context, temporal structure, and associated emotional content. These different aspects are supported by interacting brain systems rather than a single region. In particular, the hippocampus and the amygdala play complementary roles in episodic memory formation, especially when events are emotionally salient.

== The Hippocampus and the Basolateral Amygdala

The hippocampus (HPC) is a central structure for episodic memory and spatial navigation. It is well known for containing place cells, neurons that fire selectively when the animal occupies a specific position in space.

The basolateral amygdala (BLA) is involved in processing emotional significance, particularly in fear learning and aversive conditioning. Rather than encoding spatial structure, the amygdala assigns value to stimuli and events, signaling whether they are behaviorally relevant, rewarding, or threatening.

#figure(
  image("images/limbic_system.png", width: 50%),
  caption: [Primary components of the limbic system],
) <fig1>

= Exploratory Analyses and Preprocessing

== Task and dataset

Rats were pretrained to run back and forth on a linear track for water (rewards). There are three blocks to the task:

- Prerun: Behavioral test session on the track without the air puff (followed by pre-learning sleep in the home cage)
- Run: An aversive air puff is added at the same location of the track on each lap in one of the running directions (followed by a post-learning sleep)
- Postrun: Session without the air puff

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

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

We have Neuronal activity (in Hz), binned spikes from each session (matrix of size neurons x time bins). We also have the normalized position in the box, x and y position during the all sessions (matrix of size 2 x time bins). Reward and shock delivery, if an airpuff was delivered during the time bin, there will be a 1. 2 stands for right reward and 3 for left reward (matrix of size 1 x time bins). Finally, Information about neurons: their neuron number, unit number in the dataset, brain region and neuronal type (matrix of size neurons x 4).

#figure(
  image("images/data.png", width: 40%),
  caption: [Neuron description for both sessions],
) <fig2c>
== Lap Detection

As said before, the animal repeatedly traverses the corridor between the two extremities of the track. However, it frequently pauses at reward locations located at the extremities. Including these pauses would artificially inflate traversal duration and introduce behavioral variability unrelated to locomotion. So, the analysis was restricted to the central portion of the track: $x in [0.25, 0.85]$

We therefore define three spatial zones:

- Left zone: $x \leq 0.25$
- Right zone: $x \geq 0.85$
- Corridor: $0.25 < x < 0.85$

A lap is defined as a complete traversal between extremities:

- Left-to-right (LR)
- Right-to-left (RL)

Operationally, a lap begins when the animal exits one extremity and enters the corridor, and ends when it reaches the opposite extremity. Short tracking interruptions and brief backtracking movements are ignored to ensure robust segmentation.

For each lap we extract:

- Lap index
- Direction (+1 for LR, −1 for RL)
- Traversal duration

#figure(
  image("figures/lap_segmentation_rat8_postrun.png", width: 90%),
  caption: [Example of positional tracking and detected laps during post-run session of Rat 8],
) <fig3>

Only the central corridor is retained for lap analysis. Red segments correspond to laps traversed in the danger-associated direction.

== Neural Data Preprocessing

Neural activity was recorded simultaneously from hippocampus and basolateral amygdala. All analyses were restricted to excitatory neurons. Neural activity matrices take the form $X in RR^(T times N)$ where $T =$ number of time bins and $N =$ number of neurons. Each row represents the instantaneous population state at a given time bin. Neural activity was z-scored across time for each neuron. This ensures that neurons with higher firing rates do not dominate the variance structure. Normalization was applied prior to PCA.


= Principal Component Analysis

== Conceptual Framework

Neural population activity at time $t$ can be viewed as a point in an $N$-dimensional space:

$
X_(t,:) in RR^N
$

As the animal moves through the environment, the population state evolves over time, tracing a trajectory in this neural state space Principal Component Analysis identifies the directions of maximal variance in this space. The decomposition can be written as:

$
Z = X W
$

where:

+ $Z$ are the *scores* (time bins in PCA space)
+ $W$ are the *loadings* (neuron contributions)

We than have that:

+ Scores describe the position of the neural population state.
+ Loadings describe how individual neurons contribute to each population axis.

== Extraction of Danger vs Safe Samples

To focus on behaviorally relevant activity, neural activity was extracted only when the animal was within ±20 cm of the air-puff location.

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

These matrices were concatenated for PCA.


== Time-bin PCA

#figure(
  grid(
      columns: 2,
      gutter: 10pt,
    
      [
        #image("figures/pca_scores_rat8.png", width: 100%)
        #align(center)[*Rat 8*]  
      ],

      [
        #image("figures/pca_scores_rat11.png", width: 100%)
        #align(center)[*Rat 11*]
      ],
  ),

  caption: [
    PCA scores (PC1 vs PC2).  
    Each point corresponds to a time bin of neural population activity.
  ],
) <fig-pca-scores>

*TODO : COMMENT !*

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

*TODO: COMMENT !*

_neurons from both regions are intermixed which suggests that the dominanat population activity patterns involve joint contributions from both regions_

== Neurons Contributing Most to Population Axes

To better understand the population axes, neurons with the largest loading magnitudes were selected.

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/top_neurons_safe_danger_rat8.png", width: 100%)
      #align(center)[*Rat 8*]
    ],

    [
      #image("figures/top_neurons_safe_danger.png", width: 100%)
      #align(center)[*Rat 11*]
    ],
  ),

  caption: [
    Mean firing rates of neurons with largest PCA loadings.  
    Each point corresponds to one neuron.
  ],
)

Points below the diagonal correspond to neurons more active during danger traversals, while points above correspond to neurons more active during safe traversals.

*TODO: COMMENT !*

To examine temporal structure across laps, firing rates of selected neurons were plotted across successive laps.

#figure(
  grid(
    rows: 2,
    gutter: 10pt,

    [
      #image("figures/hpc_top_neurons_rat8.png", width: 90%)
      #align(center)[*Rat 8*]
    ],

    [
      #image("figures/hpc_top_neurons.png", width: 90%)
      #align(center)[*Rat 11*]
    ],
  ),

  caption: [
    Firing rate of selected neurons across laps.
  ],
)

The colored background indicates danger laps. This representation allows us to visualize whether neurons contributing strongly to population axes show consistent modulation across repeated traversals.

*TODO: COMMENT !*

== Summary of PCA Findings

Overall, PCA suggests that neural population activity does not cluster strongly by condition at the level of instantaneous time bins.

Instead:

+ Population variability is distributed across many dimensions.
+ Neurons from HPC and BLA jointly contribute to population axes.
+ Some neurons exhibit clear firing differences between danger and safe conditions.

= Time Warping and Event Alignment

Because lap duration varies substantially across traversals, direct comparison of neural activity across laps is not straightforward.   A given lap may have a lot or very few time bins depending on the animal’s instantaneous speed. To compare repeated passages through the air-puff region, we try a time-warping procedure. Our goal is to represent each lap using the same number of temporal bins while preserving alignment with the behaviorally relevant event (the air-puff).

== Puff-Centered Time Warping

We first took the spatial position of the air puff, denoted $x_"puff"$. For each lap, we then restricted the analysis to the segment of trajectory contained in a spatial window of ±20 cm around this position. This produced, for each traversal, a variable-length neural activity segment centered on the behaviorally relevant zone.

We identified within each lap, the time bin whose position was closest to $x_"puff"$. This bin was used as an anchor point and treated as the temporal center of the warped segment.

Each lap was then divided into two parts:

+ the portion before the puff-centered anchor
+ the portion after the puff-centered anchor

These two portions were resampled separately by linear interpolation so that all laps were mapped onto the same number of bins. In practice, we used 31 warped bins:

+ 15 bins before the puff
+ 1 central bin aligned with the puff
+ 15 bins after the puff

This procedure ensures that the puff occurs at the same normalized temporal position in all laps, while allowing segments of different original durations to be compared directly.

The warped representation preserves the population structure of neural activity while normalizing the time axis across repeated traversals. After warping, neural activity can be represented as a third-order tensor

$
X in RR_+^(N times T times L)
$

where:

+ $N$ is the number of selected neurons
+ $T$ is the number of warped time bins
+ $L$ is the number of laps

Each slice $X_(:,:,l)$ therefore represents the activity of the full neural population during lap $l$.

== However

Although puff-centered time warping aligns all laps at the puff, it does not guarantee that a given warped time bin corresponds to exactly the same spatial position across laps. Two traversals may differ not only in duration but also in how position evolves relative to time before and after the puff.

To assess this point, we examined, for each warped time bin, the distribution of spatial positions represented across laps.  
This analysis showed that puff-centered warping successfully aligns the central event, but that bins away from the center may still correspond to a range of nearby positions.

This observation is particularly relevant for hippocampal activity, since hippocampal neurons are known to encode spatial location.  
It motivated the consideration of an alternative normalization strategy based directly on spatial position.

== Position-Based Warping

In addition to puff-centered time warping, we implemented a second normalization procedure in which neural activity was interpolated directly onto a common spatial grid spanning the puff zone.

In this case, each normalized bin corresponds to a fixed spatial position rather than a fixed normalized time. This approach eliminates residual spatial variability across laps and makes it possible to compare neural activity at matched positions along the track.

The two approaches therefore emphasize different aspects of the data:

+ puff-centered time warping preserves an event-centered temporal interpretation
+ position-based warping preserves strict spatial correspondence across laps

Comparing these two representations helps disentangle whether observed neural structure reflects temporal dynamics around the puff or residual spatial coding.

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/position_timewarp.png", width: 100%)
      #align(center)[*Puff-centered time warping*]
    ],

    [
      #image("figures/forced_position_timewarp.png", width: 100%)
      #align(center)[*Position-based warping*]
    ],
  ),

  caption: [
    Two Time warping approaches
  ],
)

== Visualization of Activity Before and After Warping

To understand concretely how the normalization affects neural activity, we compared, for selected neurons, three representations of lap-by-lap activity around the puff zone:

+ non-warped activity, shown in real time around the puff-centered bin
+ puff-centered warped activity
+ position-warped activity

The non-warped representation retains the original time scale and therefore contains segments of different lengths across laps.  
The puff-warped representation aligns the air-puff event while normalizing traversal duration.  
The position-warped representation instead aligns activity at matched spatial locations.

#figure(
  image("figures/neuron150_warped.png", width: 90%),
  caption: [Warpings for a given neuron],
) <fig3>

*TODO: COMMENT !*

== Perspective for Tensor Decomposition

A main motivation for introducing time warping was to prepare the data for tensor-based population analyses. Without normalization, laps have different durations and cannot be stacked directly into a coherent neuron × time × lap representation. By mapping all traversals onto a common axis, warping makes it possible to build structured three-dimensional arrays suitable for non-negative matrix factorization, and more generally for tensor decomposition methods such as those considered in @Pellegrino2024.

= Non-negative Matrix Factorization

After warping, neural activity is represented as a tensor

$
X in RR_+^(N times T times L),
$

where $N$ is the number of neurons, $T$ is the number of warped time bins, and $L$ is the number of laps. Since NMF is a matrix factorization method, this tensor must first be reshaped into a two-dimensional matrix. We therefore considered three complementary slicing strategies.

== Time Slicing

#figure(
  image("figures/nmf_time_slicing_profiles.png", width: 75%),
  caption: [
    Temporal components extracted by NMF after time slicing.
    Each curve corresponds to one component of $W_"time"$.
    The dashed vertical line indicates the puff-aligned bin.
  ],
) <fig-nmf-time>

*TODO: COMMENT !*

== Neuron Slicing

#figure(
  grid(
    columns: 2,
    gutter: 10pt,

    [
      #image("figures/nmf_neuron_component1.png", width: 100%)
    ],

    [
      #image("figures/nmf_neuron_weights.png", width: 100%)
    ],
  ),

  caption: [
    NMF neuron slicing.
    Left: temporal activity profile associated with first component (of 5 in this example) across laps.
    Each curve corresponds to one lap, with colors indicating danger and safe traversals.
    Right: neuron-component weight matrix $W_"neuron"$.
  ],
) <fig-nmf-neuron>

Neuron slicing reveals groups of neurons sharing similar temporal responses around the puff. The matrix $W_"neuron"$ highlights how strongly each neuron contributes to the different latent components.

== Lap Slicing

#figure(
  image("figures/nmf_lap_slicing.png", width: 80%),
  caption: [
    NMF lap slicing.
    Each point corresponds to one lap and shows its weight the first component.
    Colors indicate danger and safe traversals.
  ],
) <fig-nmf-lap>

*TODO: COMMENT !*

== Summary

The three slicing strategies define three different NMF decompositions from the same warped tensor:

+ time slicing extracts temporal motifs around the puff
+ neuron slicing extracts groups of neurons with similar activity profiles
+ lap slicing extracts lap-level patterns that may separate danger and safe traversals

= Discussion

There is much more to try !

+ communication subspace analyses @Semedo2020Review
+ slice tensor component analysis, @Pellegrino2024

= References

#bibliography("references.bib")