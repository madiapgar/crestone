## step 1
## demux of raw 16S sequences
import os

rule demux:
    input:
        in1 = os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_barcodes.txt"),
        in2 = os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_raw_seqs.qza")
    output:
        out1 = os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_demux.qza"),
        out2 = os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_demux_details.qza")
    conda:
        QIIME
    shell:
        """
        qiime demux emp-paired \
            --m-barcodes-file {input.in1} \
            --m-barcodes-column BarcodeSequence \
            --i-seqs {input.in2} \
            --o-per-sample-sequences {output.out1} \
            --o-error-correction-details {output.out2} \
            --p-no-golay-error-correction
        """


rule demux_vis:
    input:
        os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_demux.qza")
    output:
        os.path.join(DATASET_DIR, RAW_SEQ_DIR, "{run}_demux.qzv")
    conda:
        QIIME
    shell:
        """
        qiime demux summarize \
            --i-data {input} \
            --o-visualization {output}
        """