version 1.0

task leafcutter_bam_to_junc {
    input {
        File bam_file
        String sample_id
        Int strand_specificity = 0

        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
    }
    
    String out_file = "${sample_id}.regtools_junc.txt.gz"
    
    command <<<
        set -euo pipefail
        echo $(date +"[%b %d %H:%M:%S] Extracting junctions for sample ~{sample_id}")
        
        # Select uniquely mapped reads that pass WASP filters
        filtered_bam=~{bam_file}.filtered.bam
        samtools view -h -q 255 ~{bam_file} | grep -v "vW:i:[2-7]" | samtools view -b > "${filtered_bam}"
        samtools index "${filtered_bam}"
        
        regtools junctions extract -a 8 -m 50 -M 500000 -s ~{strand_specificity} "${filtered_bam}" | gzip -c > "~{out_file}"
        
        echo $(date +"[%b %d %H:%M:%S] Done")
    >>>
    
    runtime {
        docker: "gcr.io/broad-cga-francois-gtex/leafcutter:latest"
        memory: "~{memory} GB"
        disks: "local-disk ~{disk_space} HDD"
        cpu: num_threads
        preemptible: num_preempt
    }
    
    output {
        File junc_file = out_file
    }
}

workflow leafcutter_bam_to_junc_workflow {
    input {
        Array[File] bam_files
        Array[String] sample_ids
        Int strand_specificity = 0

        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
    }
    
    scatter (i in range(length(bam_files))) {
        call leafcutter_bam_to_junc {
            input:
                bam_file = bam_files[i],
                sample_id = sample_ids[i],
                strand_specificity = strand_specificity,
                memory = memory,
                disk_space = disk_space,
                num_threads = num_threads,
                num_preempt = num_preempt
        }
    }
    
    output {
        Array[File] junctions = leafcutter_bam_to_junc.junc_file
    }
}

