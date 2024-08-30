// Define the first process
def makePostComplete(hook_url,file){
    def engine       = new groovy.text.GStringTemplateEngine()
    def hf            = new File("${projectDir}/bin/${file}")
    def json_template = engine.createTemplate(hf).make()
    def json_message  = json_template.toString()
    //println(json_message)
    // POST
    def post = new URL(hook_url).openConnection();
    post.setRequestMethod("POST")
    post.setDoOutput(true)
    post.setRequestProperty("Content-Type", "application/json")
    post.getOutputStream().write(json_message.getBytes("UTF-8"));
    def postRC = post.getResponseCode();
    if (! postRC.equals(201)) {
        log.warn(post.getErrorStream().getText());
    }
}

def create_file(file_name){
    def outputFile = new File(file_name)
    def myString = "This is the content of the file"
    outputFile.getParentFile().mkdirs()

      outputFile.write(myString)


}
process check_files {
    input:
    val name

    output:
      val message 
    exec:    
    
        println "QC 1";  
        message="QC_2"
        makePostComplete(params.qc_endpoint,"sequencing_data_quality_check.json")
}
process mapping {
    input:
    val message

    output:
      val message2 
    exec:

    println message
    message2 = "QC_3"
//Crams
    create_file(params.outdir+"/results/preprocessing/recalibrated/"+params.experiment+"/"+params.experiment+".recal.cram")   
    makePostComplete(params.qc_endpoint,"mapping_qc.json")
}

process variant_calling {
    input:
    val message2

    output:
      val message3 
    exec:

    println message2
    message3 = "dd"
    create_file(params.outdir+"/exp.vcf")
    //SNVs
    create_file(params.outdir+"/results/variant_calling/haplotypecaller/"+params.experiment+"/"+params.experiment+".haplotypecaller.filtered.vcf.gz")
     //CNVs
    create_file(params.outdir+"/results/annotsv/cnvkit/"+params.experiment+"/"+params.experiment+".tsv")
     //SVs
    create_file(params.outdir+"/results/annotsv/manta/"+params.experiment+"/"+params.experiment+".tsv")
     //Pharmacogenomics
    create_file(params.outdir+"/results/pharmacogenomics/"+params.experiment+"/results_gathered_alleles.tsv")
    //Multiqc
            create_file(params.outdir+"/results/multiqc/multiqc_report.html")
          



    makePostComplete(params.qc_endpoint,"variant.json")
}
// Define the workflow
workflow {
    // Call the first process
    check_files(name:"Hello") | mapping | variant_calling | view { it.trim() }
 }

workflow.onComplete {
        makePostComplete(params.qc_endpoint,"workflow_complete.json")
    }