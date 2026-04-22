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
In particular, interactions between the hippocampus (HPC) and the basolateral amygdala (BLA) are known to play a key role in the encoding, consolidation, and retrieval of emotionally salient experiences.

This project is based on the dataset introduced by Girardeau et al. @Girardeau2017, which investigates coordinated neural activity between hippocampus and amygdala during an associative learning task.  
In this experiment, rats repeatedly traverse a linear track where an aversive stimulus (air puff) is delivered at a fixed spatial location. Over time, animals learn to associate a specific traversal direction with the occurrence of this aversive event.

The data consist of simultaneous multi-unit recordings from multiple brain regions, including hippocampus and basolateral amygdala.  
We focus on two sessions:

+ Session 13 from Rat 8  
+ Session 27 from Rat 11  

These sessions contain the largest number of simultaneously recorded neurons in both regions, making them particularly suitable for population-level analyses.

The main objective of the project is to identify latent structures in neural population activity.  
To this end, we explore several dimensionality reduction techniques, including:

+ Principal Component Analysis (PCA)
+ Time-warping procedures to align behaviorally relevant events
+ Non-negative Matrix Factorization (NMF) applied to different tensor unfoldings

These approaches aim to characterize the geometry of population activity, identify groups of neurons with coordinated dynamics, and understand how these dynamics depend on behavioral context.

= Biological Background

#figure(
  image("images/limbic_system.png", width: 60%),
  caption: [
    Primary components of the limbic system
  ],
) <limbic_system>

== Episodic Memory and Emotional Modulation

Episodic memory refers to the ability to encode and retrieve specific events, including their spatial context, temporal structure, and associated emotional content.

A key feature of episodic memory is that it integrates multiple types of information:

+ *where* the event occurred (spatial context)  
+ *when* it occurred (temporal structure)  
+ *what it meant* (emotional valence)

These different aspects are supported by interacting brain systems rather than a single region.

In particular, the hippocampus and the amygdala play complementary roles in episodic memory formation, especially when events are emotionally salient.


== The Hippocampus

The hippocampus (HPC) is a central structure for episodic memory and spatial navigation.

It is well known for containing *place cells*, neurons that fire selectively when the animal occupies a specific position in space.  
Through this spatial coding, the hippocampus provides a representation of the environment and supports the encoding of the contextual structure of experiences.

More generally, hippocampal activity is thought to organize experiences into structured sequences, contributing to the encoding and replay of episodic memories.


== The Basolateral Amygdala

The basolateral amygdala (BLA) is involved in processing emotional significance, particularly in fear learning and aversive conditioning.

Rather than encoding spatial structure, the amygdala assigns value to stimuli and events, signaling whether they are behaviorally relevant, rewarding, or threatening.

This modulation is essential for prioritizing certain experiences in memory, especially those associated with strong emotional outcomes.


== HPC–BLA Interactions in Emotional Memory

Episodic memory for emotionally salient events relies on interactions between hippocampus and amygdala.

The hippocampus encodes the contextual and spatial aspects of an experience, while the amygdala encodes its emotional significance.  
Their interaction allows the brain to link *where an event occurred* with *how important or aversive it was*.

In the present task, the air puff provides an aversive stimulus associated with a specific location and traversal direction.  
As the animal repeatedly experiences this contingency, the task becomes a model of emotional episodic learning.

Studying the joint activity of hippocampal and amygdala populations near the puff location therefore provides insight into how spatial context and emotional value are integrated at the neural population level.

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


== Neural Data Preprocessing

Neural activity was recorded simultaneously from hippocampus and basolateral amygdala.

All analyses were restricted to *excitatory neurons*, as recommended.

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

+ $Z$ are the *scores* (time bins in PCA space)
+ $W$ are the *loadings* (neuron contributions)

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

+ *Danger*: traversal direction associated with air-puff delivery
+ *Safe*: traversal direction without air-puff

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

This suggests that the dominant population activity patterns involve *joint contributions from both regions*, rather than independent region-specific dynamics.

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

These findings motivate further analyses focusing on *population dynamics and inter-regional communication*.

= Time Warping and Event Alignment

Because lap duration varies substantially across traversals, direct comparison of neural activity across laps is not straightforward.  
A given behavioral epoch may span more or fewer time bins depending on the animal’s instantaneous speed.  
To compare repeated passages through the air-puff region, we therefore introduced a time-warping procedure.

Our goal was to represent each lap using the same number of temporal bins while preserving alignment with the behaviorally relevant event, namely the air-puff location.

== Puff-Centered Time Warping

We first estimated the spatial position of the air puff, denoted $x_"puff"$, from the run session by taking the median position of the animal during bins labeled as puff events.

For each lap, we then restricted the analysis to the segment of trajectory contained in a spatial window of ±20 cm around this position.  
This produced, for each traversal, a variable-length neural activity segment centered on the behaviorally relevant zone.

A key step was to identify, within each lap, the time bin whose position was closest to $x_"puff"$.  
This bin was used as an anchor point and treated as the temporal center of the warped segment.

Each lap was then divided into two parts:

+ the portion before the puff-centered anchor
+ the portion after the puff-centered anchor

These two portions were resampled separately by linear interpolation so that all laps were mapped onto the same number of bins.  
In practice, we used 31 warped bins:

+ 15 bins before the puff
+ 1 central bin aligned with the puff
+ 15 bins after the puff

This procedure ensures that the puff occurs at the same normalized temporal position in all laps, while allowing segments of different original durations to be compared directly.

== Interpretation of the Warping Procedure

The time warping does not define a different transformation for each neuron.  
Instead, the temporal transformation is determined once for each lap from the animal’s trajectory and then applied identically to the activity of all neurons recorded during that lap.

Thus, the warped representation preserves the population structure of neural activity while normalizing the time axis across repeated traversals.

After warping, neural activity can be represented as a third-order tensor

$
X in RR_+^(N times T times L)
$

where:

+ $N$ is the number of selected neurons
+ $T$ is the number of warped time bins
+ $L$ is the number of laps

Each slice $X_(:,:,l)$ therefore represents the activity of the full neural population during lap $l$, expressed on a common normalized temporal axis centered on the puff.

== Diagnostic: What Does a Warped Time Bin Represent?

Although puff-centered time warping aligns all laps at the puff, it does not guarantee that a given warped time bin corresponds to exactly the same spatial position across laps.  
Indeed, two traversals may differ not only in duration but also in how position evolves relative to time before and after the puff.

To assess this point, we examined, for each warped time bin, the distribution of spatial positions represented across laps.  
This analysis showed that puff-centered warping successfully aligns the central event, but that bins away from the center may still correspond to a range of nearby positions.

This observation is particularly relevant for hippocampal activity, since hippocampal neurons are known to encode spatial location.  
It motivated the consideration of an alternative normalization strategy based directly on spatial position.

== Position-Based Warping

In addition to puff-centered time warping, we implemented a second normalization procedure in which neural activity was interpolated directly onto a common spatial grid spanning the puff zone.

In this case, each normalized bin corresponds to a fixed spatial position rather than a fixed normalized time.  
This approach eliminates residual spatial variability across laps and makes it possible to compare neural activity at matched positions along the track.

The two approaches therefore emphasize different aspects of the data:

+ puff-centered time warping preserves an event-centered temporal interpretation
+ position-based warping preserves strict spatial correspondence across laps

Comparing these two representations helps disentangle whether observed neural structure reflects temporal dynamics around the puff or residual spatial coding.

== Visualization of Activity Before and After Warping

To understand concretely how the normalization affects neural activity, we compared, for selected neurons, three representations of lap-by-lap activity around the puff zone:

+ non-warped activity, shown in real time around the puff-centered bin
+ puff-centered warped activity
+ position-warped activity

The non-warped representation retains the original time scale and therefore contains segments of different lengths across laps.  
The puff-warped representation aligns the air-puff event while normalizing traversal duration.  
The position-warped representation instead aligns activity at matched spatial locations.

These comparisons provide a direct visual account of how normalization changes the apparent structure of lap-to-lap variability, and help determine whether a given neuron is better interpreted as reflecting event-centered temporal modulation or spatial tuning.

== Perspective for Tensor Decomposition

A main motivation for introducing time warping was to prepare the data for tensor-based population analyses.  
Without normalization, laps have different durations and cannot be stacked directly into a coherent neuron × time × lap representation.

By mapping all traversals onto a common axis, warping makes it possible to build structured three-dimensional arrays suitable for non-negative matrix factorization on specific unfoldings, and more generally for tensor decomposition methods such as those considered in @Pellegrino2024.


= Discussion

These exploratory analyses reveal that hippocampal and amygdala neurons jointly contribute to population activity patterns near the aversive stimulus location.

While PCA does not reveal a simple clustering of neural states by condition, it identifies neurons that contribute strongly to population variability and may participate in encoding behavioral context.

Future analyses will therefore focus on methods designed to capture structured interactions between regions, including:

+ communication subspace analyses @Semedo2020Review
+ tensor decomposition approaches @Pellegrino2024

These approaches aim to reveal structured low-dimensional interactions between hippocampus and amygdala during emotionally relevant behavior.


= References

#bibliography("references.bib")