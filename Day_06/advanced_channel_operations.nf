params.step = 0


workflow{

    // Task 1 - Read in the samplesheet.

    if (params.step == 1) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .view()
    }

    // Task 2 - Read in the samplesheet and create a meta-map with all metadata and another list with the filenames 
    //          ([[metadata_1 : metadata_1, ...], [fastq_1, fastq_2]]).
    //          Set the output to a new channel "in_ch" and view the channel. 
    //          YOU WILL NEED TO COPY AND PASTE THIS CODE INTO SOME OF THE FOLLOWING TASKS (sorry for that).

    if (params.step == 2) {
        channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map {row -> [["sample": row.sample, "strandedness": row.strandedness], [file(row.fastq_1), file(row.fastq_2)]]}
            .view()
    }
 

    // Task 3 - Now we assume that we want to handle different "strandedness" values differently.
    // Split the channel into the right amount of channels and write them all to stdout so that we can understand which is which.
    if (params.step == 3) {
        in_ch = channel.fromPath('samplesheet.csv')
                    .splitCsv(header: true)
                    .map {row -> [["sample": row.sample, "strandedness": row.strandedness], [file(row.fastq_1), file(row.fastq_2)]]}
        
        in_ch
            .branch { meta, input_files ->
                auto : meta["strandedness"] = "auto"
                            return [meta, input_files]
                forward : meta["strandedness"] = "forward"
                            return [meta, input_files]
                reverse : meta["strandedness"] = "reverse"
                            return [meta, input_files]
            }
            .set { branched_ch }
        
        branched_ch.auto.dump(tag: "auto")
        branched_ch.forward.dump(tag: "forward")
        branched_ch.reverse.dump(tag: "reverse")
        
    }

    // Task 4 - Group together all files with the same sample-id and strandedness value.
    if (params.step == 4) {
        in_ch = channel.fromPath('samplesheet.csv')
            .splitCsv(header: true)
            .map {row -> [["sample": row.sample, "strandedness": row.strandedness], [file(row.fastq_1), file(row.fastq_2)]]}
            .groupTuple()
            .view()
    }
}
