version 1.0

workflow modbamCalcMeth {
    meta {
	    author: "Shloka Negi"
        email: "shnegi@ucsc.edu"
        description: "Calculates haplotype-specific average percent modification per region, and additional stats, using modbamtools"
    }

    parameter_meta {
        MODBAM: "Assembled BAM file mapped to reference, containing modified base information"
        MODBAM_INDEX: "MODBAM index file"
        SAMPLE: "Sample Name. Will be used in output file"
        REGIONS_BED: "BED file with regions of interest"
    }

    input {
        File MODBAM
        File MODBAM_INDEX
        String SAMPLE
        File REGIONS_BED
    }

    call calcMeth {
        input:
        modbam=MODBAM,
        modbam_index=MODBAM_INDEX,
        sample=SAMPLE,
        regions_bed=REGIONS_BED
    }
    
    output {
		File output_bed = calcMeth.output_bed
    }
}

task calcMeth {
    input {
        File modbam
        File modbam_index
        String sample
        File regions_bed
        Int memSizeGB = 20
        Int threadCount = 5
        Int diskSizeGB = 5*round(size(modbam, "GB")) + 20
    }

    command <<<

        set -eux -o pipefail

        # link the modbam to make sure it's index can be found
        ln -s ~{modbam} input.bam
        ln -s ~{modbam_index} input.bam.bai

        # Run modbamtools calcMeth module
        modbamtools calcMeth --bed ~{regions_bed} \
            --threads ~{threadCount} \
            --hap \
            --out ~{sample}.regionMethylStats.bed \
            input.bam

    >>>
    
    output {
        File output_bed = "~{sample}.regionMethylStats.bed"
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "meredith705/ont_methyl:latest"
        preemptible: 1
    }
}