#!/usr/bin/env nextflow

process SPLITLETTERS {
    debug true

    input:
    tuple val(meta), val(in_str)

    output:
    tuple val(meta), path("${meta.out_name}chunk*"), emit: chunks

    script:

    """
    printf '$in_str' | split -b $meta.block_size - ${meta.out_name}chunk
    """
}

process CONVERTTOUPPER{
    debug true

    input:
    path(split_path)

    output:
    stdout

    script:
    """
    cat $split_path | tr '[a-z]' '[A-Z]'
    """

}



workflow { 
    // 1. Read in the samplesheet (samplesheet_2.csv)  into a channel. The block_size will be the meta-map
    channel.fromPath('samplesheet_2.csv').splitCsv(header: true, sep: ',')
        .map { row -> [row.subMap("block_size", "out_name"), row.input_str]}
        .set { in_ch }


    // 2. Create a process that splits the "in_str" into sizes with size block_size. The output will be a file for each block, named with the prefix as seen in the samplesheet_2
    // split the input string into chunks
    SPLITLETTERS(in_ch)

    split_ch = SPLITLETTERS.out.chunks

     // lets remove the metamap to make it easier for us, as we won't need it anymore

     split_ch = split_ch.map {meta, path -> path}.view()

    // 4. Feed these files into a process that converts the strings to uppercase. The resulting strings should be written to stdout
    // convert the chunks to uppercase and save the files to the results directory
    CONVERTTOUPPER(split_ch.flatten())


}