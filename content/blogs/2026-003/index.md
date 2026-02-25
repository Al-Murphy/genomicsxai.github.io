---
post_id: "2026-003"
title: "Fine-tuning AlphaGenome in native JAX/Haiku"
image: "alphagenome_ft.png"
math: false

authors: ["Alan Murphy", "Masayuki Nagai", "Alejandro Buendia", "Peter Koo"]

authors_display:
  - name: "Alan Murphy"
    affiliation: "Cold Spring Harbor Labs (CSHL)"
    orcid: "0000-0002-2487-8753"

  - name: "Masayuki (Moon) Nagai"
    affiliation: "Cold Spring Harbor Labs (CSHL)"
    orcid: "0009-0004-6465-2929"

  - name: "Alejandro Buendia"
    affiliation: "Stanford University"
    orcid: "0009-0001-6562-9876"
  
  - name: "Peter Koo"
    affiliation: "Cold Spring Harbor Labs (CSHL)"
    orcid: "0000-0001-8722-0038"

editor: "Editor Name"

tags: ["genomics", "fine-tuning","AlphaGenome","seq2func","JAX","haiku"]
categories: ["Blog Post"]

scope: ["tutorials"]
audience: ["general"]
labs: ["Koo lab","Kundaje lab"]

status: "submitted"
revision: 1

date_submitted: 2026-02-25
date_accepted:
date: 2026-02-25

doi: ""
revision_history:
  - version: 1
    date: 2026-02-25
    notes: "Initial submission"
---

{{< summary >}}
This post introduces [alphagenome-ft](https://github.com/genomicsxai/alphagenome_ft), a lightweight Python package for fine-tuning [AlphaGenome](https://www.nature.com/articles/s41586-025-10014-0) using native JAX/Haiku.

We highlight workflows for 

* adding custom prediction heads
* differing fine-tuning strategies
* freezing/unfreezing parameters
* attribution approaches

While fine-tuning the encoder for short sequences such as MPRA constructs has its own dedicated [post](https://genomicsxai.github.io/blogs/2026-002/), here we focus on general workflows applicable to genome-scale assays and custom heads.

**Code**:
[AlphaGenome fine-tuning utilities](https://github.com/genomicsxai/alphagenome_ft)

{{< /summary >}}

---

## Motivation

[AlphaGenome](https://www.nature.com/articles/s41586-025-10014-0) is a foundation sequence-to-function model trained on genome-scale data. Its native JAX/Haiku implementation is powerful but can be cumbersome to modify for custom tasks (we learned this the hard way!). Researchers often want to:

* Train a new head on a novel assay

* Apply low-rank adapters for efficient backbone updates

* Fine-tune the full model progressively

* Freeze certain components for stability

* Perform attribution analyses to gain insight into learned __cis__-regulatory logic

To help with this, we developed [alphagenome-ft](https://github.com/genomicsxai/alphagenome_ft) which provides a lightweight wrapper that achieves all these asks without modifying the original AlphaGenome codebase.

> _Side note:_ AlphaGenome is a deep learning model that predicts functional genomic signals (e.g., accessibility, transcription, binding) directly from DNA sequence. We call such models sequence-to-function (seq2func) models.

> _Side note 2:_ JAX/Haiku are DeepMind's frameworks which are similar to using PyTorch but optimized for large-scale accelerator workloads.

## But wait, why fine-tune AlphaGenome?

Foundation sequence models like AlphaGenome are trained on diverse genome-scale assays, allowing them to learn general regulatory sequence features. However, most research questions involve **specific cell types, assays, perturbations, or organisms** that differ from the original training distribution.

Fine-tuning adapts the pretrained model to these new contexts while preserving the regulatory knowledge already encoded in the backbone.

Benefits of fine-tuning include:

* **Improved performance with limited data** - Leverages pretrained regulatory features instead of learning from scratch.

* **Stability and efficiency via frozen parameters** - Freezing the backbone while training a new head reduces overfitting, lowers compute cost (this is important AlphaGenome is a BIG model -450m parameters), and prevents catastrophic forgetting.

* **Parameter-efficient adaptation** - Methods such as adapters or partial unfreezing allow targeted updates without retraining the full model.

* **Faster experimentation cycles** - New assays or prediction targets can be incorporated with minimal engineering effort.

* **Preservation of biological priors** - Retains learned sequence motifs and regulatory grammar that remain relevant across assays and cell types.

In practice, many workflows begin by training a task-specific head with the backbone frozen, then progressively unfreezing components if additional capacity is needed.

### Key features

* Custom prediction heads – easily register predefined, template, or fully custom heads

* Flexible parameter freezing – freeze backbone, individual modules, or heads

* Seamless integration – works with pretrained AlphaGenome weights

* Parameter inspection – explore and count model parameters

* Attribution analysis – gradient-based or in silico mutagenesis (ISM) methods

* Native JAX/Haiku – fully compatible with original AlphaGenome pipelines


* **Figure 1:** AlphaGenome fine-tuning workflows schematic

![alphagenome_ft schematic](alphagenome_ft.png "width=600 Schematic of alphagenome-ft. alphagenome-ft enables fine-tuning of AlphaGenome (architecture shown) from different, modular stages of the model (the encoder - for short sequences, the transformer - for 128 base-pair resolution, and the decoder - 1 base-pair resolution). You can control what parts of the model are frozen or free to update and you can calculate attributions, all in native JAX/Haiku.")

---

## Usage

If these features don't win you over, let's walk through how easy it is to use:

### Installation

alphagenome-ft wraps AlphaGenome and AlphaGenome Research and is available through [pip](https://pypi.org/project/alphagenome/) . Installation requires three steps:

```python
# Step 1: Install alphagenome-ft
pip install alphagenome-ft

# Step 2: Install AlphaGenome and Research
pip install git+https://github.com/google-deepmind/alphagenome.git
pip install git+https://github.com/google-deepmind/alphagenome_research.git
```

Python ≥ 3.11 is required. All other dependencies (JAX, Haiku, optax, etc.) are handled automatically.

### Quick Start: Adding new heads

There are three main ways to add heads to AlphaGenome with the package (see the figure above for architecture references):

1. **Predefined heads**

Use existing AlphaGenome head types, e.g., rna_seq, atac, chip_tf:

```python
from alphagenome_ft import (
    get_predefined_head_config,
    register_predefined_head,
    create_model_with_heads,
)

rna_config = get_predefined_head_config("rna_seq", num_tracks=4)
register_predefined_head("K562_rna_seq", rna_config)
model = create_model_with_heads("all_folds", heads=["K562_rna_seq"])
model.freeze_except_head("K562_rna_seq")

#Now ready to train!
```

2. **Template heads**

Template heads access different embeddings, which correspond to different biological resolutions - base-pair (bp) precision, regional regulatory context, and short-sequence feature extraction:

* StandardHead – 1bp embeddings (decoder output)

* TransformerHead – 128bp embeddings (transformer output)

* EncoderOnlyHead – CNN encoder output, <1 kb sequences (encoder output)

```python
from alphagenome_ft import templates, CustomHeadConfig, CustomHeadType, register_custom_head

register_custom_head(
    'my_head',
    templates.StandardHead,
    CustomHeadConfig(type=CustomHeadType.GENOME_TRACKS,
                     output_type='rna_seq',
                     num_tracks=1)
)
```

3. **Fully custom head**

We wanted to be flexible with how you do your fine-tuning so you can define your own CustomHead with arbitrary layers and loss function choices!

---

### Workflows

A full selection of four workflows are given in our [github repository](https://github.com/genomicsxai/alphagenome_ft), covering:

* Encoder-only (MPRA / short sequences)
* Heads-only fine-tuning (frozen backbone)
* LoRA-style adapters (parameter-efficient fine-tuning)
* Full-model fine-tuning

See the dedicated [MPRA post](https://genomicsxai.github.io/blogs/2026-002/) for full post dedicated to Encoder-only fine-tuning (it's great, even though I may be slightly biased as the one who wrote it ...). 

> _Side note:_ [Low-rank adapters (LoRA)](https://arxiv.org/abs/2106.09685) enable parameter-efficient fine-tuning by learning small update matrices instead of modifying the full backbone.

If unsure where to start, we recommend training a task-specific head with the backbone frozen, then progressively unfreezing components if additional capacity is needed.

---

Some extra functionality you might be interested in:

### Parameter management and checkpoints

alphagenome-ft allows:

* Modular freezing: encoder, transformer, decoder
* Freezing all heads except one: `model.freeze_except_head('my_head')`
* Saving checkpoints (heads-only or full model)
* Loading with custom head registration


## Attribution analysis

After training, alphagenome-ft also supports:

* DeepSHAP-like attributions - using dinucleotide shuffled reference sequences
* Gradient × Input
* Gradient
* In silico mutagenesis (ISM)

> _Side note:_ Attribution methods highlight which nucleotides drive predictions in these models, helping reveal regulatory motifs and sequence grammar learned by the model.

You can also visualise contributions with `plot_attribution_map` or `plot_sequence_logo` functions! See below for an example attribution map when we fine-tuned AlphaGenome's encoder on [fly STARR-seq data](https://www.nature.com/articles/s41588-022-01048-5) - See our [MPRA post](https://genomicsxai.github.io/blogs/2026-002/) for more details.

![attribution map](sequence_logo_gradient_x_input.png "width=900 Gradient x Input attribution map for AlphaGenome encoder only fine-tuning on [fly STARR-seq data](https://www.nature.com/articles/s41588-022-01048-5) - See our [MPRA post](https://genomicsxai.github.io/blogs/2026-002/) for more details on this fine-tuning. We can see the model highlights an AP-1 motif around position ~230, consistent with known enhancer regulatory logic.")

You can see we recover the AP-1 motif (`TGAsTCA`) comes up at roughly position 230 which is a known regulator for [developmental genes in flies](https://www.nature.com/articles/s41588-022-01048-5/figures/2).

---

## Implications

To take a step back, what do we get with alphagenome-ft? AlphaGenome becomes flexible to:

* Rapid adaptation to new tasks
* Modular freezing/unfreezing for stability
* Supports genome-scale or perturbation assays
* Enables downstream interpretability

AlphaGenome can now be adapted as easily as modern vision and language foundation models — opening the door to rapid regulatory genomics experimentation. So if you think AlphaGenome could be useful if applied to your research, take a look at our package!

> alphagenome-ft brings foundation-model-style transfer learning workflows to regulatory genomics.

---

## Compute requirements

* Fine-tuning with a frozen backbone typically fits on a single, high VRAM GPU (e.g., H100).
* Full-model fine-tuning or large batch training will essentially require multi-GPU or TPU setups.

---

## Code and tutorials

* [Source code & utilities](https://github.com/genomicsxai/alphagenome_ft)
* Colab notebooks: [Encoder Fine-tuning (MPRA)](https://colab.research.google.com/github/genomicsxai/alphagenome_ft/blob/main/notebooks/finetune_encoder_only_mpra.ipynb) | [Heads-only Fine-tuning](https://colab.research.google.com/github/genomicsxai/alphagenome_ft/blob/main/notebooks/finetune_rna_head_only.ipynb)

---

## TL;DR

* **AlphaGenome** is a powerful sequence-to-function foundation model, but adapting it natively in JAX/Haiku can be cumbersome.

* **alphagenome-ft** provides a lightweight wrapper for:

    * adding custom or predefined prediction heads

    * freezing and unfreezing specific modules

    * parameter-efficient fine-tuning (e.g., adapters)

    * running attribution analyses

* Most workflows can start by training a task-specific head with the backbone frozen, then progressively unfreezing if needed.

* This enables rapid adaptation to new assays while preserving pretrained regulatory knowledge.

If you want to fine-tune AlphaGenome without modifying its core codebase, alphagenome-ft is designed to make that process modular, efficient, and reproducible!

---

## References

1. Avsec, Ž. et al. Advancing regulatory variant effect prediction with AlphaGenome., 649, Nature (2026).
2. Alan Murphy, Peter Koo. "Adapting AlphaGenome to MPRA data." Genomics × AI Blog, 20 February 2026. https://genomicsxai.github.io/blogs/2026-002/
3. Hu, E. J. et al. Lora: Low-rank adaptation of large language models (2021), https://arxiv.org/abs/2106.09685. 2106.09685.
4. de Almeida, B. P., Reiter, F., Pagani, M. & Stark, A. Deepstarr predicts enhancer activity from dna sequence and enables the de novo design of synthetic enhancers., 54, Nat. genetics (2022).