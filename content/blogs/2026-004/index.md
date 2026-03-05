---
post_id: "2026-004"
title: "Implementing AlphaGenome in PyTorch"
# image: "alphagenome_ft.png"
math: false

authors: ["Danila Bredikhin", "Christopher Zou", "Martin Kjellberg", "Alejandro Buendia", "Anshul Kundaje"]

authors_display:
  - name: "Danila Bredikhin"
    affiliation: "Stanford University"
    orcid: "0000-0001-8089-6983"

  - name: "Christopher Zou"
    affiliation: "Stanford University"

  - name: "Martin Kjellberg"
    affiliation: "Stanford University"

  - name: "Alejandro Buendia"
    affiliation: "Stanford University"
    orcid: "0009-0001-6562-9876"

  - name: Anshul Kundaje  
    affiliation: "Stanford University"
    orcid: "0000-0003-3084-2287"

editor: "Editor Name"

tags: ["genomics", "fine-tuning", "AlphaGenome", "seq2func", "pytorch"]
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

This post introduces [alphagenome-pytorch](https://github.com/genomicsxai/alphagenome-pytorch), a faithful reimplementation of Google DeepMind's AlphaGenome in PyTorch, numerically verified against the original JAX implementation.

We reproduce the full AlphaGenome architecture in PyTorch and release PyTorch weights for fold-specific and distilled models. We also verify numerical equivalence of predictions across all output heads with the original JAX checkpoint. The package exposes a simple inference API that slots into any PyTorch project without requiring JAX, XLA, or TPU-specific tooling.

In this post, we walk through two concrete uses enabled by the package:

* Drop-in inference within existing PyTorch pipelines, showing how to obtain genome-wide predictions with minimal code changes.
* Variant effect prediction and in silico mutagenesis (ISM)

**Code**:
[alphagenome-pytorch](https://github.com/genomicsxai/alphagenome-pytorch)

{{< /summary >}}

---

Understanding how a single DNA change propagates through the machinery of gene regulation has been one of the grand challenges in genomics. Google DeepMind's [AlphaGenome](https://www.nature.com/articles/s41586-025-10014-0) represents a major step forward: a unified model that takes a DNA sequence of up to one million base pairs and predicts, at single base-pair resolution, hundreds of genomic tracks spanning gene expression, RNA splicing, chromatin accessibility, and more, across diverse cell types, cell lines, and conditions. With both the [model code](https://github.com/google-deepmind/alphagenome_research) and [pretrained weights](https://www.kaggle.com/models/google/alphagenome) publicly released, the community now has a powerful foundation to build on.

The original AlphaGenome model is implemented in JAX, a high-performance framework for numerical computing and deep learning. Here we present AlphaGenome's implementation in PyTorch. We strived to make it an accessible, readable, and hackable implementation for the wider community to build on and adapt for their unique use cases, in particular to enable inference of the model into existing PyTorch-based pipelines. What's more exciting is the opportunity to fine-tune the model on new datasets and cell types using your own data, and we offer an early version of fine-tuning functionality in this release.

## Numerical Equivalence with JAX

**Our PyTorch model implementation is numerically on par with the original implementation in JAX.**

Small implementation differences can silently change scientific conclusions. Therefore we strived to make sure our implementation is on par with the original JAX implementation. We added tests for numerical equivalence of the outputs of individual model heads and a full forward pass through the model, gradients, loss values.

We verified equivalence at multiple levels:

* Layer-by-layer outputs: Each convolutional block, attention mechanism, and transformer layer produces outputs within numerical precision (less than `1e-5` relative error) of the JAX implementation
* Full forward pass: End-to-end predictions across all genomic tracks match within floating-point precision
* Gradient computations: Backpropagation yields equivalent gradients, ensuring training dynamics remain faithful to the original
* Loss values: Multinomial loss computes identically on the same inputs

We converted the pre-trained weights directly from [the released checkpoints](https://www.kaggle.com/models/google/alphagenome) so that it’s easy to start working with the model with a single `.from_pretrained()` call.

## Getting Started

Using AlphaGenome in PyTorch is straightforward. Here's how to load the model and run inference on a DNA sequence:

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

The model accepts sequences up to 1,048,576 base pairs (1 Mb) and returns predictions at single-nucleotide and 128 bp resolutions for the genomic tracks it was trained on.


## What Can You Do With This?

Beyond drop-in replacement for the JAX implementation, our PyTorch version opens up several possibilities:

* Integration with PyTorch Ecosystems: Seamlessly combine AlphaGenome with other PyTorch-based genomics tools, use familiar PyTorch Lightning training loops, or integrate with libraries like Hugging Face's transformers and datasets.

* Variant Effect Prediction: Compute the impact of genetic variants by running inference on reference and alternate sequences, then comparing the predicted genomic tracks. This is particularly powerful for understanding disease-associated variants.

* In Silico Mutagenesis: Systematically mutate sequences to identify important regulatory elements and understand sequence grammar.

* Fine-tuning on Custom Data: Perhaps most excitingly, you can adapt the model to your specific cell types, conditions, or even different species. We provide utilities for fine-tuning with your own genomic assay data. In an upcoming post, we'll dive deeper into fine-tuning strategies, including data preparation, training best practices, and evaluation metrics to ensure your adapted model performs well on your specific use case.

—

The code is available on [GitHub](https://github.com/genomicsxai/alphagenome-pytorch) with detailed [documentation]() and [example notebooks]() to help you get started with this implementation. This is naturally a work in progress--we're actively developing new features, improving code and performance, and working on new examples. We welcome contributions, feedback, bug reports, and stories of how this implementation has helped your research!

---

## Code and tutorials

* [Source code & utilities](https://github.com/genomicsxai/alphagenome-pytorch)

---

## References

1. Avsec, Ž. et al. Advancing regulatory variant effect prediction with AlphaGenome., 649, Nature (2026).
