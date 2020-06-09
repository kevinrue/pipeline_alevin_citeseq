
import pandas as pd

configfile: "config.yaml"

localrules: all, alevin_all

envvars:
    "PATH"

samples = pd.read_table(config["samples"]).set_index("sample", drop=False)

rule all:
    input:
        "alevin/.done"

rule alevin_gene:
    input:
        fastq1=expand("data/{sample}_R1.fastq.gz", sample=samples['sample']),
        fastq2=expand("data/{sample}_R2.fastq.gz", sample=samples['sample']),
    output:
        directory("alevin/{sample}_rna")
    log: stderr="logs/alevin_rna_{sample}.log"
    params:
        index=config['alevin']['sa_index'],
        tgmap=config['alevin']['tgmap'],
        threads=config['alevin']['threads']
    conda:
        "envs/alevin.yaml"
    threads: config['alevin']['threads']
    resources:
        mem_mb=config['alevin']['memory_gb'] * 1024
    shell:
        """
        salmon alevin -l ISR -i {params.index} \
        -1 {input.fastq1} -2 {input.fastq2} \
        -o {output} -p {params.threads} --tgMap {params.tgmap} \
        --chromium --dumpFeatures \
        2> {log.stderr}
        """

rule alevin_adt:
    input:
        fastq1=expand("data/{sample}-ADT_R1.fastq.gz", sample=samples['sample']),
        fastq2=expand("data/{sample}-ADT_R2.fastq.gz", sample=samples['sample']),
    output:
        directory("alevin/{sample}_adt")
    log: stderr="logs/alevin_adt_{sample}.log"
    params:
        index=config['alevin']['adt_index'],
        threads=config['alevin']['threads']
    conda:
        "envs/alevin.yaml"
    threads: config['alevin']['threads']
    resources:
        mem_mb=config['alevin']['memory_gb'] * 1024
    shell:
        """
        salmon alevin -l ISR -i {params.index} \
        -1 {input.fastq1} -2 {input.fastq2} \
        -o {output} -p {params.threads} --citeseq --featureStart 0 \
        --featureLength 15 \
        2> {log.stderr}
        """

rule alevin_hto:
    input:
        fastq1=expand("data/{sample}-HTO_R1.fastq.gz", sample=samples['sample']),
        fastq2=expand("data/{sample}-HTO_R2.fastq.gz", sample=samples['sample']),
    output:
        directory("alevin/{sample}_hto")
    log: stderr="logs/alevin_hto_{sample}.log"
    params:
        index=config['alevin']['hto_index'],
        threads=config['alevin']['threads']
    conda:
        "envs/alevin.yaml"
    threads: config['alevin']['threads']
    resources:
        mem_mb=config['alevin']['memory_gb'] * 1024
    shell:
        """
        salmon alevin -l ISR -i {params.index} \
        -1 {input.fastq1} -2 {input.fastq2} \
        -o {output} -p 16 --citeseq --featureStart 0 \
        --featureLength 15 --naiveEqclass \
        2> {log.stderr}
        """

rule alevin_all:
    input:
        expand("alevin/{sample}_rna", sample=samples['sample']),
        expand("alevin/{sample}_adt", sample=samples['sample']),
        expand("alevin/{sample}_hto", sample=samples['sample'])
    output:
        "alevin/.done"
    shell:
        """touch {output}"""
