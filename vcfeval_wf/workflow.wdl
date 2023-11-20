version 1.0

workflow vcfeval_wf {
    meta {
	    author: "Shloka Negi"
        email: "shnegi@ucsc.edu"
        description: "Run vcfeval to compare 2 VCFs and output intersection, exclusive VCFs and summary stats"
    }

    parameter_meta {
        SRS_VCF: "Sample short-read VCF. Gzipped"
        LRS_VCF: "Sample long-read annotated VCF. Gzipped"
        SAMPLE: "Sample Name"
        REF: "Reference genome fasta"
    }

    input {
        File SRS_VCF
        File LRS_VCF
        File REF
        String SAMPLE
    }

    call run_vcfeval {
        input:
        srs_vcf=SRS_VCF,
        lrs_vcf=LRS_VCF,
        ref=REF,
        sample=SAMPLE
    }
    
    output {
        File tpVCF = run_vcfeval.tpVCF
        File fpVCF = run_vcfeval.fpVCF
        File fnVCF = run_vcfeval.fnVCF
		File outputSummary = run_vcfeval.outputSummary
    }
}

task run_vcfeval {
    input {
        File srs_vcf
        File lrs_vcf
        File ref
        String sample
        Int memSizeGB = 150
        Int threadCount = 64
        String dockerImage = "quay.io/shnegi/vcfeval@sha256:69e19ad005782b31767e75925e8f524fa0fe62ad1b65001f94a10bf3653e8fb0"
    }

    Int diskSizeGB = round(5*(size(srs_vcf, "GB") + size(lrs_vcf, "GB"))) + 20

	command <<<
        set -eux -o pipefail

        ## Filter SRS-VCF and index
            # Only keep PASS variants
            # Remove very long variants (>30 bps) to make sure we are not dealing with SVs
            # Remove HOM REF variants and variants "missing" GT calls
        zcat ~{srs_vcf} | bcftools filter -e 'FILTER!="PASS"' | bcftools filter -e '(GT="0/0"||GT="0|0"||GT="./.")' | bcftools filter -i '(STRLEN(REF)<30 && STRLEN(ALT)<30)' -Oz -o ~{sample}.srs.filtered.vcf.gz
        tabix -p vcf ~{sample}.srs.filtered.vcf.gz

        ## Filter LRS-VCF and index
            # Only keep PASS variants
            # Remove HOM REF variants and variants "missing" GT calls
            # Remove poor QUAL variants (<20)
            # Remove very long variants (>30 bps) to make sure we are not dealing with SVs
        zcat ~{lrs_vcf} | bcftools filter -e 'FILTER!="PASS"' | bcftools filter -e '(GT="0/0"||GT="0|0"||GT="./.")' | bcftools filter -e 'QUAL<20' | bcftools filter -i '(STRLEN(REF)<30 && STRLEN(ALT)<30)' -Oz -o ~{sample}.lrs.filtered.vcf.gz
        tabix -p vcf ~{sample}.lrs.filtered.vcf.gz

        ## link the database VCF to make sure their indexes can be found
        ln -s ~{sample}.srs.filtered.vcf.gz sample.srs.vcf.gz
        ln -s ~{sample}.srs.filtered.vcf.gz.tbi sample.srs.vcf.gz.tbi
        ln -s ~{sample}.lrs.filtered.vcf.gz sample.lrs.vcf.gz
        ln -s ~{sample}.lrs.filtered.vcf.gz.tbi sample.lrs.vcf.gz.tbi

        ## Generate RTG Sequence data file for given reference genome
        rtg format -o GRCh38.sdf ~{ref}
        ## Run vcfeval
        rtg vcfeval -b sample.srs.vcf.gz -c sample.lrs.vcf.gz -o ~{sample}_out -t GRCh38.sdf

	>>>

	output {
		File tpVCF = "~{sample}_out/tp.vcf.gz"
        File fpVCF = "~{sample}_out/fp.vcf.gz"
        File fnVCF = "~{sample}_out/fn.vcf.gz"
		File outputSummary = "~{sample}_out/summary.txt"
	}
    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: dockerImage
        preemptible: 1
    }
}
