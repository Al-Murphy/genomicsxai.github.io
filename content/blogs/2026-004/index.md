---
post_id: "2026-004"
title: "Implementing AlphaGenome in PyTorch"
math: false

authors: ["Danila Bredikhin", "Alejandro Buendia", "Martin Kjellberg", "Christopher Zou", "Xinming Tu", "Anshul Kundaje"]

authors_display:
  - name: "Danila Bredikhin"
    affiliation: "Stanford University"
    orcid: "0000-0001-8089-6983"

  - name: "Alejandro Buendia"
    affiliation: "Stanford University"
    orcid: "0009-0001-6562-9876"

  - name: "Martin Kjellberg"
    affiliation: "Stanford University"

  - name: "Christopher Zou"
    affiliation: "Stanford University"

  - name: "Xinming Tu"
    affiliation: "University of Washington"

  - name: "Anshul Kundaje"
    affiliation: "Stanford University"
    orcid: "0000-0003-3084-2287"

editor: "Editor Name"

tags: ["genomics", "finetuning", "AlphaGenome", "seq2func", "pytorch"]
categories: ["Blog Post"]

scope: ["tutorials"]
audience: ["general"]
labs: ["Kundaje lab"]

status: "submitted"
revision: 1

date_submitted: 2026-04-05
date_accepted:
date: 2026-04-05

doi: ""
revision_history:
  - version: 1
    date: 2026-04-05
    notes: "Initial submission"
---

{{< summary >}}

This post introduces [alphagenome-pytorch](https://github.com/genomicsxai/alphagenome-pytorch), a faithful reimplementation of Google DeepMind's AlphaGenome model in PyTorch.

We reproduce the full AlphaGenome architecture in PyTorch and release PyTorch weights for fold-specific and distilled models. We also verify numerical equivalence of predictions across all output tracks with the JAX checkpoint from DeepMind. Our package exposes a simple inference API that slots into any PyTorch project without requiring JAX, XLA, or TPU-specific tooling.

In this post, we review the initial release for the package and walk through two use cases it enables:

* Drop-in inference within existing PyTorch pipelines, which allows for genome-wide inference across tracks 
* Variant effect prediction and in silico mutagenesis (ISM)

**Code**:
[alphagenome-pytorch](https://github.com/genomicsxai/alphagenome-pytorch)

{{< /summary >}}

---

## Overview

Understanding how a single DNA change propagates through the complex machinery of gene regulation has been a grand challenge in genomics. Google DeepMind's [AlphaGenome](https://www.nature.com/articles/s41586-025-10014-0) represents a major step forward: a unified model that takes a DNA sequence of up to one million base pairs and predicts, at single base-pair resolution, hundreds of genomic tracks across diverse cell types, cell lines, and conditions. With both the [model code](https://github.com/google-deepmind/alphagenome_research) and [pretrained weights](https://www.kaggle.com/models/google/alphagenome) publicly released, the genomics community now has a powerful foundation to build on.

The original AlphaGenome model is implemented in [JAX](https://github.com/jax-ml/jax), a high-performance framework for numerical computing and deep learning. Here we present an implementation of AlphaGenome in PyTorch. We strived to make our implementation an accessible, readable, and hackable port of the model for the wider community to build on and adapt for their unique use cases. We also enable workflows to finetune the model on new datasets and cell types using your own data, and offer an early version of finetuning functionality in this release.

---

## Numerical Equivalence with JAX

**Our PyTorch model implementation is numerically on par with the original implementation in JAX.**

Small implementation differences can silently change scientific conclusions. Therefore we strived to make sure our implementation is on par with the original JAX implementation. We added tests for numerical equivalence of the outputs of individual model heads and a full forward pass through the model, gradients, loss values.

We verified equivalence at multiple levels:

* Layer-by-layer outputs: Each convolutional block, attention mechanism, and transformer layer produces outputs within numerical precision (less than `1e-5` relative error) of the JAX implementation
* Full forward pass: End-to-end predictions across all genomic tracks match within floating-point precision
* Gradient computations: Backpropagation yields equivalent gradients, ensuring training dynamics remain faithful to the original
* Loss values: Multinomial loss computes identically on the same inputs

We converted the pre-trained weights directly from [the released checkpoints](https://www.kaggle.com/models/google/alphagenome) so that it’s easy to start working with the model with a single `.from_pretrained()` call.

---

## Getting Started

The package can be installed from pypi as:

    pip install alphagenome-pytorch

Using AlphaGenome in PyTorch is straightforward. Here we show how to load the model and run inference on a DNA sequence:

    from alphagenome_pytorch import AlphaGenome
    from alphagenome_pytorch.utils.sequence import sequence_to_onehot_tensor
    import pyfaidx
    import torch

    device = "cuda" if torch.cuda.is_available() else "cpu"

    model = AlphaGenome.from_pretrained("model.pth", device=device)

    with pyfaidx.Fasta("hg38.fa") as genome:
        sequence = str(genome["chr1"][1_000_000:1_131_072])

    dna_onehot = sequence_to_onehot_tensor(sequence, device=device).unsqueeze(0)

    # Organism index: 0 = human, 1 = mouse
    preds = model(dna_onehot, 0)

    # Access predictions (batch, sequence, tracks) by head name and resolution:
    # - preds['atac'][1]: 1bp resolution, shape (1, 131072, 256)
    # - preds['atac'][128]: 128bp resolution, shape (1, 1024, 256)

The model accepts sequences of up to 1,048,576 base pairs (1 Mb) and returns predictions at single-nucleotide and 128 bp resolutions for the genomic tracks it was trained on.

---

## What Can You Do With This?

Beyond drop-in replacement for the JAX implementation, our PyTorch version opens up several possibilities:

* Integration with PyTorch Ecosystems: Seamlessly combine AlphaGenome with other PyTorch-based genomics tools, use familiar PyTorch Lightning training loops, or integrate with libraries like Hugging Face's transformers and datasets.
* Variant Effect Prediction: Compute the impact of genetic variants by running inference on reference and alternate sequences, and then compare the predicted genomic tracks. This is particularly powerful for understanding disease-associated variants.
* In Silico Mutagenesis (ISM): Systematically mutate sequences to identify important regulatory elements and understand sequence grammar.
* Finetuning on Custom Data: Perhaps most excitingly, you can adapt the model to your specific cell types, conditions, or even different species. We provide utilities for finetuning with your own genomic assay data. In an upcoming post, we'll dive deeper into finetuning strategies, including data preparation, training best practices, and evaluation metrics to ensure your adapted model performs well on your specific use case.

---

The code is available on [GitHub](https://github.com/genomicsxai/alphagenome-pytorch) with detailed [documentation]() and [example notebooks]() to help you get started with this implementation. This is naturally a work in progress--we're actively developing new features, improving code and performance, and working on new examples. We welcome contributions, feedback, bug reports, and stories of how this implementation has helped your research!

---

## Code and tutorials

* [Source code & utilities](https://github.com/genomicsxai/alphagenome-pytorch)
* [Tutorial notebooks]()

---

## References

1. Avsec, Ž. et al. Advancing regulatory variant effect prediction with AlphaGenome., 649, Nature (2026).
